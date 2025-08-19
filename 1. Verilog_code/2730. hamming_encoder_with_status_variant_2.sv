//SystemVerilog
module hamming_encoder_with_status(
    input clk, reset,
    input [7:0] data_in,
    input req,
    output reg ack,
    output reg [11:0] encoded_data,
    output reg busy, done
);
    reg [1:0] state, next_state;
    parameter IDLE = 0, ENCODING = 1, PIPELINE = 2, COMPLETE = 3;
    
    reg [7:0] data_pipeline;
    reg [3:0] parity_bits;
    reg req_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            encoded_data <= 0;
            data_pipeline <= 0;
            parity_bits <= 0;
            ack <= 0;
            req_reg <= 0;
        end else begin
            state <= next_state;
            req_reg <= req;
            
            case (state)
                IDLE: begin
                    if (req && !req_reg) begin
                        busy <= 1;
                        done <= 0;
                        data_pipeline <= data_in;
                        ack <= 1;
                    end else begin
                        ack <= 0;
                    end
                end
                
                ENCODING: begin
                    parity_bits[0] <= ^(data_pipeline & 8'b10101010);
                    parity_bits[1] <= ^(data_pipeline & 8'b11001100);
                    parity_bits[2] <= ^(data_pipeline & 8'b11110000);
                    parity_bits[3] <= 1'b0;
                    ack <= 0;
                end
                
                PIPELINE: begin
                    encoded_data <= {data_pipeline, parity_bits};
                    ack <= 0;
                end
                
                COMPLETE: begin
                    busy <= 0;
                    done <= 1;
                    ack <= 0;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: next_state = (req && !req_reg) ? ENCODING : IDLE;
            ENCODING: next_state = PIPELINE;
            PIPELINE: next_state = COMPLETE;
            COMPLETE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule