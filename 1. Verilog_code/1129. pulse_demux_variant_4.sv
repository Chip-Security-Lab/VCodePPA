//SystemVerilog
module pulse_demux (
    input wire clk,                      // System clock
    input wire rst_n,                    // Active low reset
    input wire pulse_in,                 // Input pulse
    input wire [1:0] route_sel,          // Routing selection
    output reg [3:0] pulse_out           // Output pulses
);
    // Stage 1: Edge detection signals
    reg pulse_detected;
    reg pulse_edge_detected;
    reg [1:0] route_sel_stage1;
    reg valid_stage1;
    
    // Stage 2: Pulse routing signals
    reg [1:0] route_sel_stage2;
    reg valid_stage2;
    reg [3:0] pulse_out_pre;
    
    // Input pulse registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_detected <= 1'b0;
        end else begin
            pulse_detected <= pulse_in;
        end
    end
    
    // Edge detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_edge_detected <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            pulse_edge_detected <= pulse_in && !pulse_detected;
            valid_stage1 <= pulse_in && !pulse_detected;
        end
    end
    
    // Routing selection registration for stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            route_sel_stage1 <= 2'b00;
        end else begin
            route_sel_stage1 <= route_sel;
        end
    end
    
    // Stage 2 valid signal propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2 routing selection propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            route_sel_stage2 <= 2'b00;
        end else begin
            route_sel_stage2 <= route_sel_stage1;
        end
    end
    
    // Pulse out pre-calculation based on routing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out_pre <= 4'b0000;
        end else begin
            pulse_out_pre <= 4'b0000;
            if (valid_stage1)
                pulse_out_pre[route_sel_stage1] <= 1'b1;
        end
    end
    
    // Final output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out <= 4'b0000;
        end else begin
            pulse_out <= pulse_out_pre;
        end
    end
endmodule