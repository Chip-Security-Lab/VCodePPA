//SystemVerilog
module BitPacker #(parameter IN_W=32, parameter OUT_W=64, parameter EFF_BITS=8) (
    input wire clk, 
    input wire ce,
    input wire [IN_W-1:0] din,
    output reg [OUT_W-1:0] dout,
    output reg valid
);
    reg [OUT_W-1:0] buffer = 0;
    reg [5:0] bit_ptr = 0;
    wire will_complete;
    wire [OUT_W-1:0] next_buffer;
    
    // 预计算逻辑（寄存器前移）
    assign will_complete = (bit_ptr + EFF_BITS) >= OUT_W;
    assign next_buffer = buffer | (din[EFF_BITS-1:0] << bit_ptr);
    
    always @(posedge clk) begin
        if(ce) begin
            buffer <= next_buffer;
            bit_ptr <= bit_ptr + EFF_BITS;
            valid <= will_complete;
            
            if(will_complete) begin
                dout <= next_buffer;
            end else begin
                dout <= 0;
            end
        end
    end
endmodule