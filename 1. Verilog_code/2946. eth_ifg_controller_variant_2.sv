//SystemVerilog
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
    
    // Buffered reset signal to reduce fanout
    reg rst_n_buf1, rst_n_buf2;
    
    // Buffer reset signal for different logic blocks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_buf1 <= 1'b0;
            rst_n_buf2 <= 1'b0;
        end else begin
            rst_n_buf1 <= 1'b1;
            rst_n_buf2 <= 1'b1;
        end
    end
    
    // Control logic for tx_done_latch using buffered reset
    always @(posedge clk or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            tx_done_latch <= 1'b0;
        end else begin
            tx_done_latch <= tx_done;
        end
    end
    
    // Reset logic for control signals
    always @(posedge clk or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            ifg_counter <= {$clog2(IFG_BYTES)+1{1'b0}};
            ifg_active <= 1'b0;
            tx_enable <= 1'b0;
        end
    end
    
    // IFG state control logic
    always @(posedge clk) begin
        if (rst_n_buf2) begin
            if (tx_done && !tx_done_latch) begin
                // Transmission just completed, start IFG
                ifg_active <= 1'b1;
                ifg_counter <= IFG_BYTES;
            end else if (ifg_active && ifg_counter == 0) begin
                // IFG period complete
                ifg_active <= 1'b0;
            end
        end
    end
    
    // IFG counter logic
    always @(posedge clk) begin
        if (rst_n_buf2) begin
            if (ifg_active && ifg_counter > 0) begin
                ifg_counter <= ifg_counter - 1'b1;
            end
        end
    end
    
    // Transmission enable control logic
    always @(posedge clk) begin
        if (rst_n_buf2) begin
            if (tx_done && !tx_done_latch) begin
                // Disable transmission when just completed
                tx_enable <= 1'b0;
            end else if (tx_request && !tx_enable && !ifg_active) begin
                // Grant transmission if requested and no IFG active
                tx_enable <= 1'b1;
            end else if (!tx_request) begin
                // Clear transmission enable when request removed
                tx_enable <= 1'b0;
            end
        end
    end
endmodule