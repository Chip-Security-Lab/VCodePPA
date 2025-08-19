//SystemVerilog
module temp_controller(
    input wire clk,
    input wire reset,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    input wire [1:0] mode, // 00:off, 01:heat, 10:cool, 11:auto
    output reg heater,
    output reg cooler,
    output reg fan,
    output reg [1:0] status, // 00:idle, 01:heating, 10:cooling
    output reg valid,        // Valid signal
    input wire ready         // Ready signal
);
    parameter [1:0] OFF = 2'b00, HEATING = 2'b01, 
                    COOLING = 2'b10, IDLE = 2'b11;
    parameter TEMP_THRESHOLD = 8'd2;
    
    // Pipeline stage 1 registers
    reg [7:0] current_temp_stage1;
    reg [7:0] target_temp_stage1;
    reg [1:0] mode_stage1;
    reg [1:0] state_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] next_state_stage2;
    reg [1:0] state_stage2;
    
    // Stage 1: Input sampling and mode decoding
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_temp_stage1 <= 8'd0;
            target_temp_stage1 <= 8'd0;
            mode_stage1 <= 2'b00;
            state_stage1 <= OFF;
            valid <= 1'b0;
        end else begin
            current_temp_stage1 <= current_temp;
            target_temp_stage1 <= target_temp;
            mode_stage1 <= mode;
            state_stage1 <= state_stage2;
            valid <= 1'b1; // Set valid high when data is ready
        end
    end
    
    // Stage 2: Next state computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            next_state_stage2 <= OFF;
            state_stage2 <= OFF;
        end else if (valid && ready) begin // Proceed only if valid and ready
            state_stage2 <= state_stage1;
            
            case (mode_stage1)
                2'b00: next_state_stage2 <= OFF;
                2'b01: next_state_stage2 <= (current_temp_stage1 < target_temp_stage1) ? HEATING : IDLE;
                2'b10: next_state_stage2 <= (current_temp_stage1 > target_temp_stage1) ? COOLING : IDLE;
                2'b11: begin
                    if (current_temp_stage1 < target_temp_stage1 - TEMP_THRESHOLD)
                        next_state_stage2 <= HEATING;
                    else if (current_temp_stage1 > target_temp_stage1 + TEMP_THRESHOLD)
                        next_state_stage2 <= COOLING;
                    else
                        next_state_stage2 <= IDLE;
                end
            endcase
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            heater <= 1'b0;
            cooler <= 1'b0;
            fan <= 1'b0;
            status <= 2'b00;
        end else if (valid && ready) begin // Proceed only if valid and ready
            case (next_state_stage2)
                OFF: begin
                    heater <= 1'b0;
                    cooler <= 1'b0;
                    fan <= 1'b0;
                    status <= 2'b00;
                end
                HEATING: begin
                    heater <= 1'b1;
                    cooler <= 1'b0;
                    fan <= 1'b1;
                    status <= 2'b01;
                end
                COOLING: begin
                    heater <= 1'b0;
                    cooler <= 1'b1;
                    fan <= 1'b1;
                    status <= 2'b10;
                end
                IDLE: begin
                    heater <= 1'b0;
                    cooler <= 1'b0;
                    fan <= 1'b0;
                    status <= 2'b00;
                end
            endcase
        end
    end
endmodule