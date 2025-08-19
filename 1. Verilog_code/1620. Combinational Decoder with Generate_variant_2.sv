//SystemVerilog
module gen_decoder #(
    parameter WIDTH = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] addr,
    input enable,
    output reg [2**WIDTH-1:0] dec_out
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam DECODE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [WIDTH:0] count;
    reg [2**WIDTH-1:0] temp_out;
    
    // State transition and output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 0;
            temp_out <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    count <= 0;
                    temp_out <= 0;
                end
                
                DECODE: begin
                    if (count < 2**WIDTH) begin
                        temp_out[count] <= (addr == count) ? 1'b1 : 1'b0;
                        count <= count + 1;
                    end
                end
                
                DONE: begin
                    count <= 0;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = DECODE;
            
            DECODE: begin
                if (count >= 2**WIDTH-1)
                    next_state = DONE;
                else
                    next_state = DECODE;
            end
            
            DONE: next_state = IDLE;
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dec_out <= 0;
        else
            dec_out <= enable ? temp_out : {(2**WIDTH){1'b0}};
    end

endmodule