module shift_register_ctrl(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] shift_mode, // 00:none, 01:left, 10:right, 11:rotate
    input wire serial_in,
    input wire parallel_load,
    input wire [7:0] parallel_data,
    output reg [7:0] data_out,
    output reg serial_out
);
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, 
                    SHIFT = 2'b10, OUTPUT = 2'b11;
    reg [1:0] state, next_state;
    reg [7:0] shift_register;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            shift_register <= 8'd0;
            data_out <= 8'd0;
            serial_out <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    // Hold current values
                end
                LOAD: begin
                    shift_register <= parallel_data;
                end
                SHIFT: begin
                    case (shift_mode)
                        2'b01: begin // Shift left
                            shift_register <= {shift_register[6:0], serial_in};
                            serial_out <= shift_register[7];
                        end
                        2'b10: begin // Shift right
                            shift_register <= {serial_in, shift_register[7:1]};
                            serial_out <= shift_register[0];
                        end
                        2'b11: begin // Rotate
                            shift_register <= {shift_register[6:0], shift_register[7]};
                            serial_out <= shift_register[7];
                        end
                    endcase
                end
                OUTPUT: begin
                    data_out <= shift_register;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (parallel_load)
                    next_state = LOAD;
                else if (enable && shift_mode != 2'b00)
                    next_state = SHIFT;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = OUTPUT;
            end
            SHIFT: begin
                next_state = OUTPUT;
            end
            OUTPUT: begin
                if (parallel_load)
                    next_state = LOAD;
                else if (enable && shift_mode != 2'b00)
                    next_state = SHIFT;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule