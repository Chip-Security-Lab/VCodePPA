//SystemVerilog
module sync_shift_rst #(parameter DEPTH=4) (
    input wire clk,
    input wire rst,
    input wire serial_in,
    output wire [DEPTH-1:0] shift_reg
);
    // Internal registers with proper retiming
    reg [DEPTH-1:0] shift_reg_internal;
    
    // Buffered copies of shift_reg_internal for fanout reduction
    reg [DEPTH-1:0] shift_reg_buf1;
    reg [DEPTH-1:0] shift_reg_buf2;
    
    // First stage retimed register
    reg serial_in_reg;
    
    always @(posedge clk) begin
        if (rst)
            serial_in_reg <= 1'b0;
        else
            serial_in_reg <= serial_in;
    end
    
    // Main shift register logic with retimed architecture
    always @(posedge clk) begin
        if (rst)
            shift_reg_internal <= {DEPTH{1'b0}};
        else begin
            shift_reg_internal[0] <= serial_in_reg;
            shift_reg_internal[DEPTH-1:1] <= shift_reg_internal[DEPTH-2:0];
        end
    end
    
    // Buffer registers to reduce fanout
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_buf1 <= {DEPTH{1'b0}};
            shift_reg_buf2 <= {DEPTH{1'b0}};
        end
        else begin
            shift_reg_buf1 <= shift_reg_internal;
            shift_reg_buf2 <= shift_reg_internal;
        end
    end
    
    // Connect buffered registers to output instead of directly using shift_reg_internal
    assign shift_reg = shift_reg_buf1;
    
endmodule