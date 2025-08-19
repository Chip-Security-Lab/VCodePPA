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
    output reg valid, // New valid signal
    input wire ready // New ready signal
);
    parameter [1:0] OFF = 2'b00, HEATING = 2'b01, 
                    COOLING = 2'b10, IDLE = 2'b11;

    // Buffer registers for high fan-out signals
    reg [7:0] current_temp_buf;
    reg [1:0] next_state_buf;
    reg [1:0] state, next_state;
    parameter TEMP_THRESHOLD = 8'd2;

    // Buffering high fan-out signals
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_temp_buf <= 8'b0;
            state <= OFF;
            heater <= 1'b0;
            cooler <= 1'b0;
            fan <= 1'b0;
            status <= 2'b00;
            valid <= 1'b0; // Initialize valid signal
        end else begin
            current_temp_buf <= current_temp; // Buffering current_temp
            state <= next_state_buf; // Using buffered next_state
            
            // Valid signal logic
            valid <= (state != OFF); // Set valid if not in OFF state
            
            if (valid && ready) begin // Proceed only if valid and ready
                case (state)
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
    end

    // Buffering next_state logic
    always @(*) begin
        case (mode)
            2'b00: next_state_buf = OFF;
            2'b01: next_state_buf = (current_temp_buf < target_temp) ? HEATING : IDLE; // Using buffered current_temp
            2'b10: next_state_buf = (current_temp_buf > target_temp) ? COOLING : IDLE; // Using buffered current_temp
            2'b11: begin
                if (current_temp_buf < target_temp - TEMP_THRESHOLD)
                    next_state_buf = HEATING;
                else if (current_temp_buf > target_temp + TEMP_THRESHOLD)
                    next_state_buf = COOLING;
                else
                    next_state_buf = IDLE;
            end
        endcase
    end
endmodule