//SystemVerilog
module debug_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire req,
    output reg ack,
    output wire [7:0] crc_out,
    output wire error_detected,
    output wire [3:0] bit_position,
    output wire processing_active
);
    parameter [7:0] POLY = 8'h07;
    
    // Pipeline stage registers
    reg [7:0] crc_stage1, crc_stage2, crc_stage3;
    reg [7:0] crc_buf1, crc_buf2;
    reg error_detected_stage1, error_detected_stage2, error_detected_reg;
    reg [3:0] bit_position_stage1, bit_position_stage2, bit_position_reg;
    reg processing_active_stage1, processing_active_stage2, processing_active_reg;
    reg req_d;
    reg [7:0] data_stage1, data_stage2;
    
    assign crc_out = crc_buf2;
    assign error_detected = error_detected_reg;
    assign bit_position = bit_position_reg;
    assign processing_active = processing_active_reg;
    
    // Stage 1: Input and request processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_d <= 1'b0;
            data_stage1 <= 8'h00;
            processing_active_stage1 <= 1'b0;
        end else begin
            req_d <= req;
            data_stage1 <= data;
            processing_active_stage1 <= req && !req_d;
        end
    end
    
    // Stage 2: CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage1 <= 8'h00;
            bit_position_stage1 <= 4'd0;
            error_detected_stage1 <= 1'b0;
            processing_active_stage2 <= 1'b0;
            data_stage2 <= 8'h00;
        end else begin
            if (processing_active_stage1) begin
                crc_stage1 <= {crc_stage1[6:0], 1'b0} ^ ((crc_stage1[7] ^ data_stage1[0]) ? POLY : 8'h0);
                bit_position_stage1 <= bit_position_stage1 + 1;
                error_detected_stage1 <= (crc_stage1 != 8'h00) && (bit_position_stage1 == 4'd7);
            end
            processing_active_stage2 <= processing_active_stage1;
            data_stage2 <= data_stage1;
        end
    end
    
    // Stage 3: Error detection and position update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage2 <= 8'h00;
            bit_position_stage2 <= 4'd0;
            error_detected_stage2 <= 1'b0;
            processing_active_reg <= 1'b0;
        end else begin
            crc_stage2 <= crc_stage1;
            bit_position_stage2 <= bit_position_stage1;
            error_detected_stage2 <= error_detected_stage1;
            processing_active_reg <= processing_active_stage2;
        end
    end
    
    // Stage 4: Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage3 <= 8'h00;
            bit_position_reg <= 4'd0;
            error_detected_reg <= 1'b0;
        end else begin
            crc_stage3 <= crc_stage2;
            bit_position_reg <= bit_position_stage2;
            error_detected_reg <= error_detected_stage2;
        end
    end
    
    // Output buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_buf1 <= 8'h00;
            crc_buf2 <= 8'h00;
        end else begin
            crc_buf1 <= crc_stage3;
            crc_buf2 <= crc_buf1;
        end
    end
    
    // ACK generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
        end else if (req && !req_d) begin
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
endmodule