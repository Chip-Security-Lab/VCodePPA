//SystemVerilog
module multiply_and_operator (
    input clk,
    input rst_n,
    
    // Input interface (Valid-Ready)
    input [7:0] data_a,
    input [7:0] data_b,
    input valid_in,
    output ready_in,
    
    // Output interface (Valid-Ready)
    output [15:0] product,
    output [7:0] and_result,
    output valid_out,
    input ready_out
);

    // Internal registers
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [15:0] product_reg;
    reg [7:0] and_result_reg;
    reg valid_out_reg;
    
    // State machine states
    localparam IDLE = 1'b0;
    localparam PROCESS = 1'b1;
    
    reg state;
    reg next_state;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (valid_in && ready_in)
                    next_state = PROCESS;
                else
                    next_state = IDLE;
            end
            PROCESS: begin
                if (valid_out_reg && ready_out)
                    next_state = IDLE;
                else
                    next_state = PROCESS;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            product_reg <= 16'b0;
            and_result_reg <= 8'b0;
            valid_out_reg <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (valid_in && ready_in) begin
                        a_reg <= data_a;
                        b_reg <= data_b;
                        valid_out_reg <= 1'b0;
                    end
                end
                PROCESS: begin
                    product_reg <= a_reg * b_reg;
                    and_result_reg <= a_reg & b_reg;
                    valid_out_reg <= 1'b1;
                end
            endcase
        end
    end
    
    // Output assignments
    assign ready_in = (state == IDLE);
    assign product = product_reg;
    assign and_result = and_result_reg;
    assign valid_out = valid_out_reg;
    
endmodule