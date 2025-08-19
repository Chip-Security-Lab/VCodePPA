//SystemVerilog
module gray_code_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] binary_priority,
    output reg [$clog2(WIDTH)-1:0] gray_priority,
    output reg valid
);

    // LUT for binary to gray conversion
    reg [2:0] gray_lut [0:7];
    initial begin
        gray_lut[0] = 3'b000;
        gray_lut[1] = 3'b001;
        gray_lut[2] = 3'b011;
        gray_lut[3] = 3'b010;
        gray_lut[4] = 3'b110;
        gray_lut[5] = 3'b111;
        gray_lut[6] = 3'b101;
        gray_lut[7] = 3'b100;
    end

    // Priority encoder using LUT-based approach
    reg [2:0] next_binary_priority;
    reg [2:0] next_gray_priority;
    reg next_valid;
    
    always @(*) begin
        next_valid = |data_in;
        next_binary_priority = 0;
        
        casex(data_in)
            8'b1xxxxxxx: next_binary_priority = 3'd7;
            8'b01xxxxxx: next_binary_priority = 3'd6;
            8'b001xxxxx: next_binary_priority = 3'd5;
            8'b0001xxxx: next_binary_priority = 3'd4;
            8'b00001xxx: next_binary_priority = 3'd3;
            8'b000001xx: next_binary_priority = 3'd2;
            8'b0000001x: next_binary_priority = 3'd1;
            8'b00000001: next_binary_priority = 3'd0;
            default: next_binary_priority = 3'd0;
        endcase
        
        next_gray_priority = gray_lut[next_binary_priority];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_priority <= 0;
            gray_priority <= 0;
            valid <= 0;
        end else begin
            binary_priority <= next_binary_priority;
            gray_priority <= next_gray_priority;
            valid <= next_valid;
        end
    end
endmodule