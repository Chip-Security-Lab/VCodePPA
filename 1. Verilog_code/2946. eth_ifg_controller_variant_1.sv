//SystemVerilog
module eth_ifg_controller #(parameter IFG_BYTES = 12) (
    input wire clk,
    input wire rst_n,
    input wire tx_request,
    input wire tx_done,
    output reg tx_enable,
    output reg ifg_active
);
    // Internal signals
    reg [$clog2(IFG_BYTES):0] ifg_counter;
    
    // Registered input signals (moved forward)
    reg tx_done_r, tx_request_r;
    
    // Edge detection for tx_done
    wire tx_done_edge = tx_done_r & ~tx_done_prev;
    reg tx_done_prev;
    
    // Buffered reset signals with push-forward retiming
    wire rst_n_buf = rst_n; // Direct connection eliminates unnecessary registers
    
    // Input registration - moved registers forward
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_done_r <= 1'b0;
            tx_request_r <= 1'b0;
            tx_done_prev <= 1'b0;
        end else begin
            tx_done_r <= tx_done;
            tx_request_r <= tx_request;
            tx_done_prev <= tx_done_r;
        end
    end
    
    // Combined counter and control logic
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            ifg_counter <= {$clog2(IFG_BYTES)+1{1'b0}};
            ifg_active <= 1'b0;
            tx_enable <= 1'b0;
        end else begin
            // IFG Counter logic
            if (tx_done_edge) begin
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
            end
            
            // Enable logic combined with counter logic
            if (!ifg_active && tx_request_r && !tx_enable && !tx_done_edge) begin
                // Grant transmission if requested and no IFG active
                tx_enable <= 1'b1;
            end else if (!tx_request_r && !tx_done_edge) begin
                tx_enable <= 1'b0;
            end
        end
    end
endmodule