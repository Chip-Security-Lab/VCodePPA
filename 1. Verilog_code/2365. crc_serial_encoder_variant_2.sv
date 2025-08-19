//SystemVerilog
module crc_serial_encoder #(parameter DW=16)(
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    output reg serial_out
);
    // Stage 1: Data preparation and CRC calculation
    reg [DW-1:0] data_stage1;
    reg [4:0] crc_reg;
    reg [4:0] crc_stage1;
    reg valid_stage1, valid_stage2;
    
    // Stage 2: Shift registers
    reg [DW+4:0] shift_reg;
    reg shift_active;
    reg [5:0] shift_counter;
    
    // Pre-calculated CRC XOR result to reduce critical path
    wire [4:0] crc_xor_result;
    assign crc_xor_result = crc_reg ^ data_in[DW-1:DW-5];
    
    // Data capture (sequential logic) - simplified
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 1'b0;
            crc_reg <= 5'h1F;
            crc_stage1 <= 5'h1F;
        end else if (en) begin
            data_stage1 <= data_in;
            valid_stage1 <= 1'b1;
            crc_reg <= crc_xor_result;
            crc_stage1 <= crc_xor_result;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Shift control and serial output preparation logic
    reg serial_out_next;
    reg shift_active_next;
    reg [5:0] shift_counter_next;
    reg [DW+4:0] shift_reg_next;
    
    // Combinational logic to determine next state
    always @(*) begin
        // Default values (hold current state)
        shift_active_next = shift_active;
        shift_counter_next = shift_counter;
        shift_reg_next = shift_reg;
        serial_out_next = serial_out;
        
        if (valid_stage1) begin
            // Load shift register with new data
            shift_reg_next = {data_stage1, crc_stage1};
            shift_active_next = 1'b1;
            shift_counter_next = DW + 5; // Total bits to shift
            serial_out_next = data_stage1[DW-1]; // First bit output immediately
        end else if (shift_active) begin
            if (shift_counter > 1) begin
                // Balanced logic for shift operations
                shift_reg_next = {shift_reg[DW+3:0], 1'b0};
                shift_counter_next = shift_counter - 1;
                serial_out_next = shift_reg[DW+3];
            end else if (shift_counter == 1) begin
                // Last bit
                serial_out_next = shift_reg[0];
                shift_active_next = 1'b0;
                shift_counter_next = 0;
            end
        end
    end
    
    // Combined sequential logic for shift register, counter and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            shift_active <= 1'b0;
            shift_counter <= 0;
            valid_stage2 <= 1'b0;
            serial_out <= 1'b0;
        end else begin
            shift_reg <= shift_reg_next;
            shift_active <= shift_active_next;
            shift_counter <= shift_counter_next;
            serial_out <= serial_out_next;
            valid_stage2 <= valid_stage1;
        end
    end
endmodule