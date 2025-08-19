//SystemVerilog - IEEE 1364-2005
module tdm_crossbar (
    input wire clock, reset,
    input wire [7:0] in0, in1, in2, in3,
    output reg [7:0] out0, out1, out2, out3
);
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Time slot counter management - Stage 0
    reg [1:0] time_slot;
    reg [1:0] time_slot_stage1, time_slot_stage2;
    
    // Input data pipeline registers
    reg [7:0] in0_stage1, in1_stage1, in2_stage1, in3_stage1;
    reg [7:0] in0_stage2, in1_stage2, in2_stage2, in3_stage2;
    
    // Selected data for each output in pipeline stages
    reg [7:0] out0_data_stage1, out1_data_stage1, out2_data_stage1, out3_data_stage1;
    reg [7:0] out0_data_stage2, out1_data_stage2, out2_data_stage2, out3_data_stage2;
    
    // Stage 0: Time slot counter and input registration
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            time_slot <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            time_slot <= time_slot + 1'b1;
            valid_stage1 <= 1'b1; // Data is valid after first clock
        end
    end
    
    // Stage 1: Input registration and data selection
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset pipeline registers
            time_slot_stage1 <= 2'b00;
            in0_stage1 <= 8'h00;
            in1_stage1 <= 8'h00;
            in2_stage1 <= 8'h00;
            in3_stage1 <= 8'h00;
            valid_stage2 <= 1'b0;
            
            out0_data_stage1 <= 8'h00;
            out1_data_stage1 <= 8'h00;
            out2_data_stage1 <= 8'h00;
            out3_data_stage1 <= 8'h00;
        end else begin
            // Forward time slot and input data to stage 1
            time_slot_stage1 <= time_slot;
            in0_stage1 <= in0;
            in1_stage1 <= in1;
            in2_stage1 <= in2;
            in3_stage1 <= in3;
            valid_stage2 <= valid_stage1;
            
            // Perform data selection based on time slot
            // Output 0 data selection
            case (time_slot)
                2'b00: out0_data_stage1 <= in0;
                2'b01: out0_data_stage1 <= in3;
                2'b10: out0_data_stage1 <= in2;
                2'b11: out0_data_stage1 <= in1;
            endcase
            
            // Output 1 data selection
            case (time_slot)
                2'b00: out1_data_stage1 <= in1;
                2'b01: out1_data_stage1 <= in0;
                2'b10: out1_data_stage1 <= in3;
                2'b11: out1_data_stage1 <= in2;
            endcase
            
            // Output 2 data selection
            case (time_slot)
                2'b00: out2_data_stage1 <= in2;
                2'b01: out2_data_stage1 <= in1;
                2'b10: out2_data_stage1 <= in0;
                2'b11: out2_data_stage1 <= in3;
            endcase
            
            // Output 3 data selection
            case (time_slot)
                2'b00: out3_data_stage1 <= in3;
                2'b01: out3_data_stage1 <= in2;
                2'b10: out3_data_stage1 <= in1;
                2'b11: out3_data_stage1 <= in0;
            endcase
        end
    end
    
    // Stage 2: Final output generation
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset pipeline registers
            time_slot_stage2 <= 2'b00;
            in0_stage2 <= 8'h00;
            in1_stage2 <= 8'h00;
            in2_stage2 <= 8'h00;
            in3_stage2 <= 8'h00;
            
            out0_data_stage2 <= 8'h00;
            out1_data_stage2 <= 8'h00;
            out2_data_stage2 <= 8'h00;
            out3_data_stage2 <= 8'h00;
            
            // Reset output registers
            out0 <= 8'h00;
            out1 <= 8'h00;
            out2 <= 8'h00;
            out3 <= 8'h00;
        end else begin
            // Forward all data to stage 2
            time_slot_stage2 <= time_slot_stage1;
            in0_stage2 <= in0_stage1;
            in1_stage2 <= in1_stage1;
            in2_stage2 <= in2_stage1;
            in3_stage2 <= in3_stage1;
            
            out0_data_stage2 <= out0_data_stage1;
            out1_data_stage2 <= out1_data_stage1;
            out2_data_stage2 <= out2_data_stage1;
            out3_data_stage2 <= out3_data_stage1;
            
            // Final output assignment
            if (valid_stage2) begin
                out0 <= out0_data_stage1;
                out1 <= out1_data_stage1;
                out2 <= out2_data_stage1;
                out3 <= out3_data_stage1;
            end
        end
    end
    
endmodule