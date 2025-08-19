//SystemVerilog
module wakeup_ismu(
    input clk, rst_n,
    input sleep_mode,
    input [7:0] int_src,
    input [7:0] wakeup_mask,
    output reg wakeup,
    output reg [7:0] pending_int
);
    // Pre-compute wake sources and move register backward through combinational logic
    reg [7:0] int_src_reg;
    reg [7:0] wakeup_mask_reg;
    reg sleep_mode_reg;
    reg [7:0] pending_int_internal;
    
    // Buffer registers for high fan-out signals
    reg [7:0] int_src_buf1, int_src_buf2;
    reg [7:0] h0_buf1, h0_buf2;
    wire [7:0] h0; // Wake-up condition pre-computation
    
    // Pre-compute wake condition to reduce critical path
    assign h0 = int_src_reg & ~wakeup_mask_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_reg <= 8'h0;
            wakeup_mask_reg <= 8'h0;
            sleep_mode_reg <= 1'b0;
            pending_int_internal <= 8'h0;
            wakeup <= 1'b0;
            pending_int <= 8'h0;
            int_src_buf1 <= 8'h0;
            int_src_buf2 <= 8'h0;
            h0_buf1 <= 8'h0;
            h0_buf2 <= 8'h0;
        end else begin
            // Register inputs first
            int_src_reg <= int_src;
            wakeup_mask_reg <= wakeup_mask;
            sleep_mode_reg <= sleep_mode;
            
            // Buffer high fan-out signals
            int_src_buf1 <= int_src_reg;
            int_src_buf2 <= int_src_reg;
            h0_buf1 <= h0;
            h0_buf2 <= h0;
            
            // Update pending_int in internal register using buffer
            pending_int_internal <= pending_int_internal | int_src_buf1;
            
            // Push results to output registers using buffer
            pending_int <= pending_int_internal | int_src_buf2;
            
            // Compute wakeup with buffered h0 signal
            wakeup <= sleep_mode_reg && |h0_buf2;
        end
    end
endmodule