module fsm_display_codec (
    input clk, rst_n,
    input [23:0] pixel_in,
    input start_conversion,
    output reg [15:0] pixel_out,
    output reg busy, done
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam OUTPUT = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] processed_data;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = start_conversion ? PROCESS : IDLE;
            PROCESS: next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Data processing and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 16'h0000;
            busy <= 1'b0;
            done <= 1'b0;
            processed_data <= 16'h0000;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                end
                PROCESS: begin
                    // RGB888 to RGB565 conversion
                    processed_data <= {pixel_in[23:19], pixel_in[15:10], pixel_in[7:3]};
                    busy <= 1'b1;
                    done <= 1'b0;
                end
                OUTPUT: begin
                    pixel_out <= processed_data;
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule