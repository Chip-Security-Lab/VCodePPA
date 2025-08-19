module eth_ifg_controller #(parameter IFG_BYTES = 12) (
    input wire clk,
    input wire rst_n,
    input wire tx_request,
    input wire tx_done,
    output reg tx_enable,
    output reg ifg_active
);
    reg [$clog2(IFG_BYTES):0] ifg_counter;
    reg tx_done_latch;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifg_counter <= {$clog2(IFG_BYTES)+1{1'b0}};
            tx_enable <= 1'b0;
            ifg_active <= 1'b0;
            tx_done_latch <= 1'b0;
        end else begin
            tx_done_latch <= tx_done;
            
            if (tx_done && !tx_done_latch) begin
                // Transmission just completed, start IFG
                ifg_active <= 1'b1;
                ifg_counter <= IFG_BYTES;
                tx_enable <= 1'b0;
            end else if (ifg_active) begin
                // Count down IFG
                if (ifg_counter > 0)
                    ifg_counter <= ifg_counter - 1'b1;
                else
                    ifg_active <= 1'b0;
            end else if (tx_request && !tx_enable && !ifg_active) begin
                // Grant transmission if requested and no IFG active
                tx_enable <= 1'b1;
            end else if (!tx_request) begin
                tx_enable <= 1'b0;
            end
        end
    end
endmodule