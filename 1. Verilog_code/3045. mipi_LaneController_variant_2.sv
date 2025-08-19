//SystemVerilog
module MIPI_LaneController #(
    parameter NUM_LANES = 4,
    parameter MAX_BURST = 16
)(
    input wire clk,
    input wire rst,
    input wire [NUM_LANES-1:0] lane_enable,
    input wire [7:0] tx_data,
    output reg [NUM_LANES-1:0] hs_en,
    output reg [NUM_LANES*8-1:0] lane_data,
    output reg data_consumed
);

    // Pipeline stage 1 registers
    reg [NUM_LANES-1:0] lane_enable_stage1;
    reg [7:0] tx_data_stage1;
    reg [1:0] state_stage1;
    reg [3:0] burst_counter_stage1;
    reg any_lane_enabled_stage1;
    
    // Pipeline stage 2 registers
    reg [NUM_LANES-1:0] lane_enable_stage2;
    reg [7:0] tx_data_stage2;
    reg [1:0] state_stage2;
    reg [3:0] burst_counter_stage2;
    reg burst_complete_stage2;
    
    // Pipeline stage 3 registers
    reg [NUM_LANES-1:0] hs_en_stage3;
    reg [NUM_LANES*8-1:0] lane_data_stage3;
    reg data_consumed_stage3;
    reg [1:0] state_stage3;
    
    wire burst_complete;
    wire any_lane_enabled;
    wire [3:0] next_burst_counter;
    wire [3:0] inverted_burst_counter;
    wire [3:0] burst_counter_diff;
    
    // Conditional inversion subtractor implementation
    assign inverted_burst_counter = ~burst_counter_stage2;
    assign burst_counter_diff = burst_counter_stage2 - 4'b1;
    assign next_burst_counter = (burst_counter_stage2 == 4'b0) ? 4'b0 : burst_counter_diff;
    
    assign burst_complete = (burst_counter_stage2 == MAX_BURST-1);
    assign any_lane_enabled = |lane_enable;
    
    // Stage 1: Input and state control
    always @(posedge clk) begin
        if (rst) begin
            lane_enable_stage1 <= {NUM_LANES{1'b0}};
            tx_data_stage1 <= 8'b0;
            state_stage1 <= 2'b00;
            burst_counter_stage1 <= 4'b0;
            any_lane_enabled_stage1 <= 1'b0;
        end else begin
            lane_enable_stage1 <= lane_enable;
            tx_data_stage1 <= tx_data;
            any_lane_enabled_stage1 <= any_lane_enabled;
            
            case(state_stage3)
                2'b00: begin
                    if (any_lane_enabled_stage1) begin
                        state_stage1 <= 2'b01;
                    end
                end
                2'b01: begin
                    burst_counter_stage1 <= next_burst_counter;
                    if (burst_complete_stage2) begin
                        state_stage1 <= 2'b10;
                    end
                end
                2'b10: begin
                    if (!any_lane_enabled_stage1) 
                        state_stage1 <= 2'b00;
                end
                default: state_stage1 <= 2'b00;
            endcase
        end
    end
    
    // Stage 2: Data processing
    always @(posedge clk) begin
        if (rst) begin
            lane_enable_stage2 <= {NUM_LANES{1'b0}};
            tx_data_stage2 <= 8'b0;
            state_stage2 <= 2'b00;
            burst_counter_stage2 <= 4'b0;
            burst_complete_stage2 <= 1'b0;
        end else begin
            lane_enable_stage2 <= lane_enable_stage1;
            tx_data_stage2 <= tx_data_stage1;
            state_stage2 <= state_stage1;
            burst_counter_stage2 <= burst_counter_stage1;
            burst_complete_stage2 <= burst_complete;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk) begin
        if (rst) begin
            hs_en_stage3 <= {NUM_LANES{1'b0}};
            lane_data_stage3 <= {NUM_LANES*8{1'b0}};
            data_consumed_stage3 <= 1'b0;
            state_stage3 <= 2'b00;
        end else begin
            state_stage3 <= state_stage2;
            
            case(state_stage2)
                2'b00: begin
                    hs_en_stage3 <= {NUM_LANES{1'b0}};
                    data_consumed_stage3 <= 1'b0;
                end
                2'b01: begin
                    hs_en_stage3 <= lane_enable_stage2;
                    lane_data_stage3 <= {NUM_LANES{tx_data_stage2}};
                    data_consumed_stage3 <= 1'b1;
                end
                2'b10: begin
                    hs_en_stage3 <= {NUM_LANES{1'b0}};
                    data_consumed_stage3 <= 1'b0;
                end
                default: begin
                    hs_en_stage3 <= {NUM_LANES{1'b0}};
                    data_consumed_stage3 <= 1'b0;
                end
            endcase
        end
    end
    
    // Output assignments
    assign hs_en = hs_en_stage3;
    assign lane_data = lane_data_stage3;
    assign data_consumed = data_consumed_stage3;
    
endmodule