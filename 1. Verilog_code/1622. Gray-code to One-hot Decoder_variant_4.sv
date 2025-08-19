//SystemVerilog
module gray_to_onehot (
    input wire clk,
    input wire rst_n,
    input wire [2:0] gray_in,
    output reg [7:0] onehot_out
);

    // Pipeline stage 1: Gray to binary conversion
    reg [2:0] binary_stage1;
    reg [2:0] binary_stage2;
    
    // Pipeline stage 2: Binary to one-hot conversion
    reg [7:0] onehot_stage1;
    
    // Stage 1: Gray to binary conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_stage1 <= 3'b0;
        end else begin
            binary_stage1[2] <= gray_in[2];
            binary_stage1[1] <= gray_in[2] ^ gray_in[1];
            binary_stage1[0] <= gray_in[1] ^ gray_in[0];
        end
    end
    
    // Stage 2: Binary to one-hot conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_stage2 <= 3'b0;
            onehot_stage1 <= 8'b0;
        end else begin
            binary_stage2 <= binary_stage1;
            case (binary_stage1)
                3'b000: onehot_stage1 <= 8'b00000001;
                3'b001: onehot_stage1 <= 8'b00000010;
                3'b010: onehot_stage1 <= 8'b00000100;
                3'b011: onehot_stage1 <= 8'b00001000;
                3'b100: onehot_stage1 <= 8'b00010000;
                3'b101: onehot_stage1 <= 8'b00100000;
                3'b110: onehot_stage1 <= 8'b01000000;
                3'b111: onehot_stage1 <= 8'b10000000;
                default: onehot_stage1 <= 8'b00000000;
            endcase
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onehot_out <= 8'b0;
        end else begin
            onehot_out <= onehot_stage1;
        end
    end

endmodule