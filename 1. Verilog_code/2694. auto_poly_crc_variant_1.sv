//SystemVerilog
module auto_poly_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] data_len,
    input wire valid_in,
    output reg ready_out,
    output reg [15:0] crc_out,
    output reg valid_out
);

    // Pipeline stages
    reg [15:0] polynomial_stage1;
    reg [7:0] data_stage1;
    reg [7:0] data_len_stage1;
    reg valid_stage1;
    
    reg [15:0] crc_stage2;
    reg [15:0] polynomial_stage2;
    reg [7:0] data_stage2;
    reg valid_stage2;
    
    reg [15:0] crc_stage3;
    reg valid_stage3;

    // Polynomial selection logic
    always @(posedge clk) begin
        if (rst) begin
            polynomial_stage1 <= 16'h1021;
        end else if (valid_in && ready_out) begin
            case (data_len)
                8'd8:    polynomial_stage1 <= 16'h0007;
                8'd16:   polynomial_stage1 <= 16'h8005;
                default: polynomial_stage1 <= 16'h1021;
            endcase
        end
    end

    // Data stage 1 control
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 8'h00;
            data_len_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else if (valid_in && ready_out) begin
            data_stage1 <= data;
            data_len_stage1 <= data_len;
            valid_stage1 <= 1'b1;
        end else if (!valid_in) begin
            valid_stage1 <= 1'b0;
        end
    end

    // Ready signal control
    always @(posedge clk) begin
        if (rst) begin
            ready_out <= 1'b1;
        end
    end

    // CRC calculation stage 2
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 16'h0000;
            polynomial_stage2 <= 16'h1021;
            data_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            crc_stage2 <= {crc_out[14:0], 1'b0} ^ 
                         ((crc_out[15] ^ data_stage1[0]) ? polynomial_stage1 : 16'h0000);
            polynomial_stage2 <= polynomial_stage1;
            data_stage2 <= data_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3 pipeline
    always @(posedge clk) begin
        if (rst) begin
            crc_stage3 <= 16'h0000;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            crc_stage3 <= crc_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Output control
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
        end
    end

    // CRC output assignment
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 16'h0000;
        end else if (valid_stage3) begin
            crc_out <= crc_stage3;
        end
    end

endmodule