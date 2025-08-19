//SystemVerilog
module programmable_poly_crc(
    input wire clk,
    input wire rst,
    input wire [15:0] poly_in,
    input wire poly_valid,
    output reg poly_ready,
    input wire [7:0] data,
    input wire data_valid,
    output reg data_ready,
    output reg [15:0] crc,
    output reg crc_valid,
    input wire crc_ready
);

    // Pipeline stage 1 registers
    reg [15:0] polynomial;
    reg [15:0] crc_stage1;
    reg [7:0] data_reg_stage1;
    reg [2:0] bit_counter_stage1;
    reg processing_stage1;
    
    // Pipeline stage 2 registers
    reg [15:0] crc_stage2;
    reg [7:0] data_reg_stage2;
    reg [2:0] bit_counter_stage2;
    reg processing_stage2;
    
    // Pipeline stage 3 registers
    reg [15:0] crc_stage3;
    reg [7:0] data_reg_stage3;
    reg [2:0] bit_counter_stage3;
    reg processing_stage3;
    
    // Control signals
    reg poly_ready_stage1;
    reg data_ready_stage1;
    reg crc_valid_stage3;
    
    // Stage 1: Input and polynomial configuration
    always @(posedge clk) begin
        if (rst) begin
            polynomial <= 16'h1021;
            crc_stage1 <= 16'hFFFF;
            poly_ready_stage1 <= 1'b1;
            data_ready_stage1 <= 1'b1;
            processing_stage1 <= 1'b0;
            bit_counter_stage1 <= 3'd0;
            data_reg_stage1 <= 8'd0;
        end else begin
            // Polynomial configuration
            if (poly_valid && poly_ready_stage1) begin
                polynomial <= poly_in;
                poly_ready_stage1 <= 1'b0;
            end else if (!poly_ready_stage1) begin
                poly_ready_stage1 <= 1'b1;
            end
            
            // Data input
            if (data_valid && data_ready_stage1 && !processing_stage1) begin
                data_reg_stage1 <= data;
                data_ready_stage1 <= 1'b0;
                processing_stage1 <= 1'b1;
                bit_counter_stage1 <= 3'd0;
                crc_stage1 <= crc;
            end else if (processing_stage1) begin
                data_reg_stage1 <= data_reg_stage1;
                bit_counter_stage1 <= bit_counter_stage1 + 1'b1;
                processing_stage1 <= (bit_counter_stage1 < 3'd7);
                data_ready_stage1 <= (bit_counter_stage1 == 3'd7);
            end
        end
    end
    
    // Stage 2: First CRC calculation
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 16'hFFFF;
            data_reg_stage2 <= 8'd0;
            bit_counter_stage2 <= 3'd0;
            processing_stage2 <= 1'b0;
        end else begin
            processing_stage2 <= processing_stage1;
            data_reg_stage2 <= data_reg_stage1;
            bit_counter_stage2 <= bit_counter_stage1;
            
            if (processing_stage1) begin
                crc_stage2 <= {crc_stage1[14:0], 1'b0} ^ 
                             ((crc_stage1[15] ^ data_reg_stage1[bit_counter_stage1]) ? 
                              polynomial : 16'h0000);
            end
        end
    end
    
    // Stage 3: Final CRC calculation and output
    always @(posedge clk) begin
        if (rst) begin
            crc <= 16'hFFFF;
            crc_valid_stage3 <= 1'b0;
            data_reg_stage3 <= 8'd0;
            bit_counter_stage3 <= 3'd0;
            processing_stage3 <= 1'b0;
        end else begin
            processing_stage3 <= processing_stage2;
            data_reg_stage3 <= data_reg_stage2;
            bit_counter_stage3 <= bit_counter_stage2;
            
            if (processing_stage2) begin
                crc <= {crc_stage2[14:0], 1'b0} ^ 
                       ((crc_stage2[15] ^ data_reg_stage2[bit_counter_stage2]) ? 
                        polynomial : 16'h0000);
                crc_valid_stage3 <= (bit_counter_stage2 == 3'd7);
            end else if (crc_valid_stage3 && crc_ready) begin
                crc_valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign poly_ready = poly_ready_stage1;
    assign data_ready = data_ready_stage1;
    assign crc_valid = crc_valid_stage3;
    
endmodule