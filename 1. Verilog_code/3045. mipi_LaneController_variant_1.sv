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
    reg [NUM_LANES-1:0] hs_en_stage1;
    reg [1:0] state_stage1;
    reg [3:0] burst_counter_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers  
    reg [NUM_LANES-1:0] hs_en_stage2;
    reg [NUM_LANES*8-1:0] lane_data_stage2;
    reg [1:0] state_stage2;
    reg [3:0] burst_counter_stage2;
    reg valid_stage2;
    reg data_consumed_stage2;

    // Pipeline stage 1 logic
    always @(posedge clk) begin
        if (rst) begin
            hs_en_stage1 <= 0;
            state_stage1 <= 0;
            burst_counter_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            if (state_stage1 == 0 && |lane_enable) begin
                hs_en_stage1 <= lane_enable;
                state_stage1 <= 1;
                valid_stage1 <= 1;
            end else if (state_stage1 == 1) begin
                valid_stage1 <= 1;
            end else if (state_stage1 == 2) begin
                hs_en_stage1 <= 0;
                if (!(|lane_enable)) begin
                    state_stage1 <= 0;
                    valid_stage1 <= 0;
                end
            end
        end
    end

    // Pipeline stage 2 logic
    always @(posedge clk) begin
        if (rst) begin
            hs_en_stage2 <= 0;
            lane_data_stage2 <= 0;
            state_stage2 <= 0;
            burst_counter_stage2 <= 0;
            valid_stage2 <= 0;
            data_consumed_stage2 <= 0;
        end else begin
            if (valid_stage1) begin
                hs_en_stage2 <= hs_en_stage1;
                state_stage2 <= state_stage1;
                burst_counter_stage2 <= burst_counter_stage1;
                valid_stage2 <= 1;

                if (state_stage1 == 1) begin
                    lane_data_stage2 <= {NUM_LANES{tx_data}};
                    burst_counter_stage2 <= burst_counter_stage1 + 1;
                    data_consumed_stage2 <= 1;
                    if (burst_counter_stage1 == MAX_BURST-1) begin
                        state_stage2 <= 2;
                        data_consumed_stage2 <= 0;
                    end
                end
            end else begin
                valid_stage2 <= 0;
            end
        end
    end

    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            hs_en <= 0;
            lane_data <= 0;
            data_consumed <= 0;
        end else begin
            if (valid_stage2) begin
                hs_en <= hs_en_stage2;
                lane_data <= lane_data_stage2;
                data_consumed <= data_consumed_stage2;
            end else begin
                hs_en <= 0;
                data_consumed <= 0;
            end
        end
    end

endmodule