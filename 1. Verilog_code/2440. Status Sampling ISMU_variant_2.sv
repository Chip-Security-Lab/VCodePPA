//SystemVerilog
module status_sampling_ismu #(parameter WIDTH = 8)(
    input clk, rstn,
    input [WIDTH-1:0] int_raw,
    input sample_en,
    output reg [WIDTH-1:0] int_status,
    output reg status_valid
);
    reg [WIDTH-1:0] int_prev;
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    
    // 实现先行借位减法器
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = (~int_raw[i] & borrow[i]) | (~int_raw[i] & int_prev[i]) | (int_prev[i] & borrow[i]);
            assign diff[i] = int_raw[i] ^ int_prev[i] ^ borrow[i];
        end
    endgenerate
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_status <= {WIDTH{1'b0}};
            int_prev <= {WIDTH{1'b0}};
            status_valid <= 1'b0;
        end else begin
            int_prev <= int_raw;
            if (sample_en) begin
                int_status <= int_raw;
                status_valid <= 1'b1;
            end else
                status_valid <= 1'b0;
        end
    end
endmodule