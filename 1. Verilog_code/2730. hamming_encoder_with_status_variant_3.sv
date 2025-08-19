//SystemVerilog
module hamming_encoder_with_status(
    input clk, reset,
    input req,
    output reg ack,
    input [7:0] data_in,
    output reg [11:0] encoded_data,
    output reg busy, done
);
    reg [1:0] state;
    parameter IDLE = 0, ENCODING = 1, COMPLETE = 2;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE; busy <= 0; done <= 0; encoded_data <= 0; ack <= 0;
        end else case (state)
            IDLE: if (req) begin
                state <= ENCODING; busy <= 1; done <= 0; ack <= 1;
            end else begin
                ack <= 0;
            end
            ENCODING: begin
                encoded_data[0] <= ^(data_in & 8'b10101010);
                encoded_data[1] <= ^(data_in & 8'b11001100);
                encoded_data[2] <= ^(data_in & 8'b11110000);
                encoded_data[11:3] <= {data_in, 1'b0};
                state <= COMPLETE;
            end
            COMPLETE: begin 
                busy <= 0; 
                done <= 1; 
                state <= IDLE; 
                ack <= 0;
            end
        endcase
    end
endmodule