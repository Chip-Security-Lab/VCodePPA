//SystemVerilog
module pulse_width_measure #(
    parameter COUNTER_WIDTH = 32
)(
    input clk,
    input rst_n,               // Added reset signal
    input pulse_in,
    input valid_in,            // Input valid signal
    output reg valid_out,      // Output valid signal
    output reg [COUNTER_WIDTH-1:0] width_count
);

    // Stage 1: Edge detection
    reg pulse_in_stage1;
    reg last_state_stage1;
    reg valid_stage1;
    
    // Stage 2: Measurement control
    reg measuring_stage2;
    reg valid_stage2;
    reg [COUNTER_WIDTH-1:0] counter_stage2;
    wire rising_edge, falling_edge;
    
    // Stage 3: Counter update
    reg measuring_stage3;
    reg [COUNTER_WIDTH-1:0] counter_stage3;
    reg valid_stage3;
    
    // Edge detection logic
    assign rising_edge = pulse_in_stage1 && !last_state_stage1;
    assign falling_edge = !pulse_in_stage1 && last_state_stage1;
    
    // Stage 1: Sample input and detect edges
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_in_stage1 <= 0;
            last_state_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            pulse_in_stage1 <= pulse_in;
            last_state_stage1 <= pulse_in_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Measurement control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            measuring_stage2 <= 0;
            counter_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (rising_edge) begin
                measuring_stage2 <= 1;
                counter_stage2 <= 0;
            end else if (falling_edge) begin
                measuring_stage2 <= 0;
                counter_stage2 <= counter_stage2;
            end else if (measuring_stage2) begin
                counter_stage2 <= counter_stage2 + 1;
            end else begin
                counter_stage2 <= counter_stage2;
            end
        end
    end
    
    // Stage 3: Final counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            measuring_stage3 <= 0;
            counter_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            measuring_stage3 <= measuring_stage2;
            counter_stage3 <= counter_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            width_count <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage3;
            if (!measuring_stage3 && valid_stage3) begin
                width_count <= counter_stage3;
            end
        end
    end
    
endmodule