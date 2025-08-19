//SystemVerilog
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
                    SHIFT1 = 2'b10, SHIFT2 = 2'b11, OUTPUT = 2'b100;
    reg [2:0] state, next_state;
    reg [7:0] shift_register_stage1, shift_register_stage2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            shift_register_stage1 <= 8'd0;
            shift_register_stage2 <= 8'd0;
            data_out <= 8'd0;
            serial_out <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    // Hold current values
                end
                LOAD: begin
                    shift_register_stage1 <= parallel_data;
                end
                SHIFT1: begin
                    case (shift_mode)
                        2'b01: begin // Shift left
                            shift_register_stage2 <= {shift_register_stage1[6:0], serial_in};
                            serial_out <= shift_register_stage1[7];
                        end
                        2'b10: begin // Shift right
                            shift_register_stage2 <= {serial_in, shift_register_stage1[7:1]};
                            serial_out <= shift_register_stage1[0];
                        end
                        2'b11: begin // Rotate
                            shift_register_stage2 <= {shift_register_stage1[6:0], shift_register_stage1[7]};
                            serial_out <= shift_register_stage1[7];
                        end
                    endcase
                end
                SHIFT2: begin
                    shift_register_stage1 <= shift_register_stage2; // Pass to next stage
                end
                OUTPUT: begin
                    data_out <= shift_register_stage1;
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
                    next_state = SHIFT1;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = OUTPUT;
            end
            SHIFT1: begin
                next_state = SHIFT2;
            end
            SHIFT2: begin
                next_state = OUTPUT;
            end
            OUTPUT: begin
                if (parallel_load)
                    next_state = LOAD;
                else if (enable && shift_mode != 2'b00)
                    next_state = SHIFT1;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule