//SystemVerilog
module PacketParser #(
    parameter CRC_POLY = 32'h04C11DB7
)(
    input clk, rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_result,
    output reg packet_valid
);
    // Pipeline control signals
    reg data_valid_stage1, data_valid_stage2, data_valid_stage3;
    reg [7:0] data_in_stage1, data_in_stage2;
    
    // State machine definitions
    localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, CRC_CHECK = 2'b11;
    reg [1:0] current_state, next_state;
    reg [1:0] current_state_stage1, current_state_stage2;
    
    reg [31:0] crc_reg, crc_reg_stage1, crc_reg_stage2, crc_reg_stage3;
    reg [3:0] byte_counter, byte_counter_stage1;
    reg crc_calc_en, crc_calc_en_stage1, crc_calc_en_stage2;
    
    // CRC calculation pipeline signals
    reg [31:0] crc_partial_result;
    reg [7:0] crc_data_stage1, crc_data_stage2;
    reg [31:0] crc_input_stage1, crc_input_stage2;
    
    // Modified CRC calculation function with partial results for pipelining
    function [31:0] calc_crc_bit;
        input bit_val;
        input [31:0] crc;
        begin
            if ((bit_val ^ crc[31]) == 1'b1)
                calc_crc_bit = (crc << 1) ^ CRC_POLY;
            else
                calc_crc_bit = crc << 1;
        end
    endfunction

    // Stage 1: Input Registration and State Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage1 <= 1'b0;
            data_in_stage1 <= 8'h0;
            current_state <= IDLE;
            current_state_stage1 <= IDLE;
            byte_counter <= 4'h0;
            byte_counter_stage1 <= 4'h0;
            crc_calc_en <= 1'b0;
        end else begin
            data_valid_stage1 <= data_valid;
            data_in_stage1 <= data_in;
            current_state <= next_state;
            current_state_stage1 <= current_state;
            
            // Byte counter logic
            if (data_valid && current_state == HEADER) begin
                if (byte_counter == 3)
                    byte_counter <= 0;
                else
                    byte_counter <= byte_counter + 1;
            end
            byte_counter_stage1 <= byte_counter;
            
            // Enable CRC calculation for payload data
            crc_calc_en <= (data_valid && current_state == PAYLOAD);
        end
    end

    // Next state logic (combinational)
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (data_valid && data_in == 8'h55) next_state = HEADER;
            HEADER: if (data_valid && byte_counter == 3) next_state = PAYLOAD;
            PAYLOAD: if (data_valid && data_in == 8'hAA) next_state = CRC_CHECK;
            CRC_CHECK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Stage 2: CRC Calculation Pipeline - Setup
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage2 <= 1'b0;
            data_in_stage2 <= 8'h0;
            current_state_stage2 <= IDLE;
            crc_calc_en_stage1 <= 1'b0;
            crc_reg <= 32'hFFFFFFFF;
            crc_data_stage1 <= 8'h0;
            crc_input_stage1 <= 32'hFFFFFFFF;
        end else begin
            data_valid_stage2 <= data_valid_stage1;
            data_in_stage2 <= data_in_stage1;
            current_state_stage2 <= current_state_stage1;
            crc_calc_en_stage1 <= crc_calc_en;
            
            // CRC initial setup
            if (current_state == IDLE && next_state == HEADER) begin
                crc_reg <= 32'hFFFFFFFF;
            end
            
            // Prepare CRC calculation inputs
            if (crc_calc_en) begin
                crc_data_stage1 <= data_in;
                crc_input_stage1 <= crc_reg;
            end
        end
    end
    
    // Stage 3: CRC Calculation Pipeline - First 4 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_calc_en_stage2 <= 1'b0;
            crc_data_stage2 <= 8'h0;
            crc_input_stage2 <= 32'h0;
            crc_partial_result <= 32'h0;
        end else begin
            crc_calc_en_stage2 <= crc_calc_en_stage1;
            crc_data_stage2 <= crc_data_stage1;
            
            // Process first 4 bits
            if (crc_calc_en_stage1) begin
                crc_partial_result <= calc_crc_bit(crc_data_stage1[7], crc_input_stage1);
                crc_partial_result <= calc_crc_bit(crc_data_stage1[6], crc_partial_result);
                crc_partial_result <= calc_crc_bit(crc_data_stage1[5], crc_partial_result);
                crc_partial_result <= calc_crc_bit(crc_data_stage1[4], crc_partial_result);
            end
        end
    end
    
    // Stage 4: CRC Calculation Pipeline - Last 4 bits and result update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage3 <= 1'b0;
            crc_reg_stage3 <= 32'h0;
        end else begin
            data_valid_stage3 <= data_valid_stage2;
            
            // Process last 4 bits and update CRC register
            if (crc_calc_en_stage2) begin
                crc_reg_stage1 <= calc_crc_bit(crc_data_stage2[3], crc_partial_result);
                crc_reg_stage1 <= calc_crc_bit(crc_data_stage2[2], crc_reg_stage1);
                crc_reg_stage1 <= calc_crc_bit(crc_data_stage2[1], crc_reg_stage1);
                crc_reg_stage1 <= calc_crc_bit(crc_data_stage2[0], crc_reg_stage1);
                crc_reg <= crc_reg_stage1;
            end
            
            crc_reg_stage3 <= crc_reg;
        end
    end

    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_result <= 32'h0;
            packet_valid <= 1'b0;
        end else begin
            // CRC result output logic
            if (current_state_stage2 == CRC_CHECK) begin
                crc_result <= crc_reg_stage3;
            end
            
            // Packet valid output logic
            if (current_state_stage2 == CRC_CHECK) begin
                packet_valid <= (crc_reg_stage3 == 32'h0);
            end else begin
                packet_valid <= 1'b0;
            end
        end
    end
endmodule