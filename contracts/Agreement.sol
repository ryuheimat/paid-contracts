pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./AgreementModels.sol";

//
// @dev Contains agreements templates or documents created by user
//
// Create AgreementUtils
contract Agreement is Ownable, AgreementModels {

    using SafeERC20 for IERC20;

    enum AgreementStatus {
        PARTY_INIT,
        COUNTERPARTY_SIGNED,
        PUBLISHED,
        DISPUTE_INIT,
        DISPUTE_ACCEPTED,
        DISPUTE_REJECTED,
        VERDICT_PARTY_FOR,
        VERDICT_PARTY_AGAINST,
        ARBRITRATION
    }

    event AgreementEvents(
        uint256 indexed id,
        bytes32 formTemplateId,
        address indexed partySource,
        address indexed partyDestination,
        string agreementStoredReference,
        uint status
    );

    uint256 private count;
    // Agreement documents, which has references to decentralized storage and
    // onchain metadata
    mapping(uint256 => AgreementDocument) public agreements;
    // user - plantilla - metadata
    mapping(address => mapping(bytes32 => bytes)) public agreementForms;

    // Agreement templates - preloaded from migration
    mapping(bytes32 => bytes) agreementTemplates;

    constructor() public {}

    function partyCreate(
        uint256 validUntil,
        address counterparty,
        string memory multiaddrReference,
        bytes32 agreementFormTemplateId,
        bytes memory agreementForm,
        bytes memory digest
    )
        public
        returns (
            uint256
        )
    {
        return execute(
            msg.sender,
            counterparty,
            uint256(0),
            validUntil,
            multiaddrReference,
            agreementFormTemplateId,
            agreementForm,
            uint(AgreementStatus.PARTY_INIT),
            block.timestamp,
            block.timestamp,
            digest
        );
    }

    function counterPartiesSign(
        uint agreementId,
        uint256 validUntil,
        string memory multiaddrReference,
        bytes32 agreementFormTemplateId,
        bytes memory agreementForm,
        bytes memory digest
    )
        public
        returns (
            uint256
        )
    {
        AgreementDocument memory doc = agreements[agreementId];
        return execute(
            doc.fromSigner.signatory,
            msg.sender,
            agreementId,
            validUntil,
            multiaddrReference,
            agreementFormTemplateId,
            agreementForm,
            uint(AgreementStatus.COUNTERPARTY_SIGNED),
            doc.created_at,
            block.timestamp,
            digest
        );
    }

    // Creates an agreement document
    // Contains a reference for content stored off chain
    function execute(
        address party,
        address counterparty,
        uint256 agreementId,
        uint256 validUntil,
        string memory multiaddrReference,
        bytes32 agreementFormTemplateId,
        bytes memory agreementForm,
        uint status,
        uint created_at,
        uint updated_at,
        bytes memory digest
    )
        internal
        returns (
            uint256
        )
    {
        if (status == uint(AgreementStatus.PARTY_INIT)) {
            count++;
            agreements[count] = AgreementDocument({
                fromSigner: Party({ signatory: party }),
                toSigner: Party({ signatory: counterparty }),
                escrowed: false,
                validUntil: validUntil,
                status: status,
                agreementForm: agreementForm,
                created_at: created_at,
                updated_at: updated_at,
                file: Content({
                    multiaddressReference: multiaddrReference,
                    digest: digest
                })
            });
            // Emit Event when Create Agreements
            emit AgreementEvents(
                count,
                agreementFormTemplateId,
                party,
                counterparty,
                multiaddrReference,
                status
            );
            return count;
        } else if (status == uint(AgreementStatus.COUNTERPARTY_SIGNED)) {
            agreements[agreementId] = AgreementDocument({
                fromSigner: Party({ signatory: party }),
                toSigner: Party({ signatory: counterparty }),
                escrowed: false,
                validUntil: validUntil,
                status: status,
                agreementForm: agreementForm,
                created_at: created_at,
                updated_at: updated_at,
                file: Content({
                    multiaddressReference: multiaddrReference,
                    digest: digest
                })
            });
            // Emit Event when Counterparty Sign the Agreementes
            emit AgreementEvents(
                agreementId,
                agreementFormTemplateId,
                party,
                counterparty,
                multiaddrReference,
                status
            );
            return agreementId;
        } else {
            return uint256(0);
        }
    }

    function setAgreementTemplate(bytes32 id, bytes memory content)
        public
        returns (bool)
    {
        // TODO: add requires
        agreementTemplates[id] = content;
        return true;
    }


    function getFormById(uint agreementId, bool isCounterparty, bytes32 formId) public view returns (bytes memory) {
        require(isCounterparty == true &&
         msg.sender == agreements[agreementId].toSigner.signatory);

        return agreementForms[msg.sender][formId];
    }

    function has(uint256 id) public view returns (bool) {
        return agreements[id].validUntil != 0;
    }

    function get(uint256 id) public view returns (AgreementDocument memory) {
        require(agreements[id].validUntil != 0, "Invalid agreement id");
        return agreements[id];
    }
    // Get balance of the Toekn ERC20, of the address recipient
    function getBalanceToken(IERC20 token, address recipient) public view returns (uint256) {
        return token.balanceOf(recipient);
    }
    // Withdraw amount of token indicate of any token ERC20, and send to any address selected
    function withdraw(IERC20 token, address sender,address recipient, uint256 amount) public {
        require(amount >= token.balanceOf(sender), "Enough Balance for this Operation");
        token.safeTransferFrom(sender, recipient, amount);
    }
}
