//SystemVerilog
module auto_poly_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] data_len,
    output reg [15:0] crc_out
);

    // Stage 1: Polynomial Selection
    reg [15:0] polynomial_stage1;
    reg [7:0] data_stage1;
    reg [7:0] data_len_stage1;
    reg valid_stage1;

    always @(*) begin
        case (data_len_stage1)
            8'd8:    polynomial_stage1 = 16'h0007;
            8'd16:   polynomial_stage1 = 16'h8005;
            default: polynomial_stage1 = 16'h1021;
        endcase
    end

    // Stage 2: CRC Calculation
    reg [15:0] crc_stage2;
    reg [15:0] polynomial_stage2;
    reg [7:0] data_stage2;
    reg valid_stage2;

    // Stage 3: Final Output
    reg [15:0] crc_stage3;
    reg valid_stage3;

    // Pipeline Registers
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            crc_out <= 16'h0000;
        end else begin
            // Stage 1
            data_stage1 <= data;
            data_len_stage1 <= data_len;
            valid_stage1 <= 1'b1;

            // Stage 2
            polynomial_stage2 <= polynomial_stage1;
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                crc_stage2 <= {crc_out[14:0], 1'b0} ^ 
                            ((crc_out[15] ^ data_stage1[0]) ? polynomial_stage1 : 16'h0000);
            end

            // Stage 3
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                crc_stage3 <= crc_stage2;
            end

            // Output
            if (valid_stage3) begin
                crc_out <= crc_stage3;
            end
        end
    end

endmodule