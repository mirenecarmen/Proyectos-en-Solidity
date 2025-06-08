// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SubastaBadBunny {
        address payable public seller;
        address payable public commissionReceiver;
        string public itemName;
        uint public minimumBid;
        uint public auctionStart;
        uint public auctionEnd;
        uint public extensionTime = 10 minutes; // tiempo de extension por nuevas pujas
        uint public duration = 60 minutes; // duracion total de la subasta
        uint public commissionPercent = 2; // comision del 2%

        struct Bid {
            address payable bidder;
            uint amount;
        }


        Bid[] public bidHistory;
        mapping(address => uint) public refunds;

        address public highestBidder;
        uint public highestBid;
        bool public ended;

        event NewBid(address bidder, uint amount);
        event AuctionEnded(address winner , uint amount);

        modifier onlyWhileActive(){
            require(block.timestamp >= auctionStart && block.timestamp <= auctionEnd, "Auction is not open yet.");
            _;
        }
        modifier onlyAfterEnd() {
            require(block.timestamp > auctionEnd, "Auction has not ended yet.");
            _;
        }

        constructor(uint _minimumBid) {
            require(_minimumBid > 0, "Minimum bid must be greater than zero.");
            itemName = "VIP pass for Bud Bunny concert in Buenos Aires, river Plate,2026";
            seller = payable(msg.sender); // vendedor = quien despliega el contrato
            commissionReceiver = payable(msg.sender); // se puede cambiar esto por otro address si se desea
            minimumBid = _minimumBid; // valor minimo de inicio
            auctionStart = block.timestamp; // fecha y hora de inicio = ahora
            auctionEnd = auctionStart + duration; // duracion = 60 minutos
        }
        function placeBid() external payable onlyWhileActive {
            require(msg.value >= minimumBid, "Bid is below minimum."); // validar minimo
            require(msg.value >= highestBid + (highestBid * 5)/100 , "Bid must be at least 5% higher than current highest.");

            if (highestBidder != address(0)) {
                refunds[highestBidder] += highestBid; // reembolsar oferta anterior
            }
            highestBidder = msg.sender; // nuevo mejor postor
            highestBid = msg.value;
            bidHistory.push(Bid(payable(msg.sender),msg.value)); // guardar en historial

            // extender la subasta si se realiza una oferta dentro de los ultimos 10 minutos

            if(auctionEnd - block.timestamp <= extensionTime) {
                auctionEnd = block.timestamp + extensionTime;
            }
            emit NewBid(msg.sender, msg.value);
        }
        function withdrawRefund() external {// pull over push pattern
            uint amount = refunds[msg.sender];
            require(amount > 0, "No refunds available.");
            refunds[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }

        //Asignacion
        /*cuando termina la subasta trnsferir pago al vendedor, descontando comision y declarar ganador */
        function finalizeAuction() external onlyAfterEnd {
            require(!ended, "Auction already finalized.");
            ended = true;

            uint commissionAmount = (highestBid * commissionPercent) / 100;
            uint payout = highestBid - commissionAmount;
            require(highestBid > 0, "No bids placed.");

            seller.transfer(payout); //pagar al vendedor

            if (commissionReceiver != address(0)) {
            commissionReceiver.transfer(commissionAmount);
            }

            emit AuctionEnded(highestBidder, highestBid); // emitir evento de cierre
        }
        function getwinner() external view returns (address, uint) {
            return (highestBidder , highestBid);
        }
        function getBidHistory() external view returns (Bid[] memory) {
            return bidHistory;
        }
    

}