//SystemVerilog
// Clock detection module
module MIPI_ClockDetector #(
    parameter LANE_COUNT = 2
)(
    input wire [LANE_COUNT-1:0] hs_clk,
    output wire all_clks_active,
    output wire any_clk_active
);
    assign all_clks_active = &hs_clk;
    assign any_clk_active = |hs_clk;
endmodule

// Data capture module with pipeline
module MIPI_DataCapture #(
    parameter DATA_WIDTH = 8,
    parameter LANE_COUNT = 2
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [LANE_COUNT*DATA_WIDTH-1:0] hs_data,
    input wire capture_en,
    output reg [DATA_WIDTH-1:0] captured_data
);
    reg [DATA_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (enable) begin
            data_stage1 <= hs_data[DATA_WIDTH-1:0];
            valid_stage1 <= capture_en;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            captured_data <= 0;
        end else if (enable && valid_stage1) begin
            captured_data <= data_stage1;
        end
    end
endmodule

// State control module with pipeline
module MIPI_StateController #(
    parameter LANE_COUNT = 2
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire all_clks_active,
    input wire any_clk_active,
    input wire hs_clk_active,
    output reg [1:0] state,
    output reg data_valid
);
    localparam IDLE = 0, ACTIVE = 1, SYNC = 2;
    
    reg [1:0] state_stage1;
    reg valid_stage1;
    reg [1:0] state_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            valid_stage1 <= 0;
        end else if (enable) begin
            case(state)
                IDLE: 
                    if (all_clks_active) begin
                        state_stage1 <= ACTIVE;
                        valid_stage1 <= 0;
                    end
                ACTIVE:
                    if (hs_clk_active) begin
                        valid_stage1 <= 1;
                        state_stage1 <= SYNC;
                    end
                SYNC: begin
                    valid_stage1 <= 0;
                    if (!any_clk_active) state_stage1 <= IDLE;
                end
            endcase
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            valid_stage2 <= 0;
        end else if (enable) begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_valid <= 0;
        end else if (enable) begin
            state <= state_stage2;
            data_valid <= valid_stage2;
        end
    end
endmodule

// Top-level MIPI Synchronous Receiver module
module MIPI_SyncReceiver #(
    parameter DATA_WIDTH = 8,
    parameter LANE_COUNT = 2
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [LANE_COUNT-1:0] hs_clk,
    input wire [LANE_COUNT*DATA_WIDTH-1:0] hs_data,
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire data_valid
);
    wire all_clks_active;
    wire any_clk_active;
    wire [1:0] state;
    wire capture_en;
    
    MIPI_ClockDetector #(
        .LANE_COUNT(LANE_COUNT)
    ) clock_detector (
        .hs_clk(hs_clk),
        .all_clks_active(all_clks_active),
        .any_clk_active(any_clk_active)
    );
    
    MIPI_StateController #(
        .LANE_COUNT(LANE_COUNT)
    ) state_controller (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .all_clks_active(all_clks_active),
        .any_clk_active(any_clk_active),
        .hs_clk_active(hs_clk[0]),
        .state(state),
        .data_valid(data_valid)
    );
    
    MIPI_DataCapture #(
        .DATA_WIDTH(DATA_WIDTH),
        .LANE_COUNT(LANE_COUNT)
    ) data_capture (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .hs_data(hs_data),
        .capture_en(state == ACTIVE && hs_clk[0]),
        .captured_data(rx_data)
    );
endmodule