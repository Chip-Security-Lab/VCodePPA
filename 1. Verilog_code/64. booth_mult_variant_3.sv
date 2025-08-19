//SystemVerilog
module booth_mult (
    input clk,
    input rst_n,
    input valid_in,
    output reg ready_in,
    input [7:0] X, Y,
    output reg valid_out,
    input ready_out,
    output reg [15:0] P
);
    reg [15:0] A;
    reg [8:0] Q;
    reg [2:0] state;
    reg [2:0] next_state;
    reg [2:0] counter;
    reg [7:0] X_reg;
    reg [7:0] Y_reg;
    
    // State definitions
    localparam IDLE = 3'b000;
    localparam CALC = 3'b001;
    localparam DONE = 3'b010;
    
    // State transition logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid_in) next_state = CALC;
            end
            CALC: begin
                if (counter == 3'b111) next_state = DONE;
            end
            DONE: begin
                if (ready_out) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            counter <= 3'b0;
            A <= 16'b0;
            Q <= 9'b0;
            X_reg <= 8'b0;
            Y_reg <= 8'b0;
            P <= 16'b0;
            valid_out <= 1'b0;
            ready_in <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    ready_in <= 1'b1;
                    if (valid_in) begin
                        X_reg <= X;
                        Y_reg <= Y;
                        A <= 16'b0;
                        Q <= {Y, 1'b0};
                        counter <= 3'b0;
                        ready_in <= 1'b0;
                    end
                end
                
                CALC: begin
                    ready_in <= 1'b0;
                    valid_out <= 1'b0;
                    
                    case(Q[1:0])
                        2'b01: A <= A + {X_reg, 8'b0};
                        2'b10: A <= A - {X_reg, 8'b0};
                        default: A <= A;
                    endcase
                    
                    {A, Q} <= {A[15], A, Q[8:1]};
                    counter <= counter + 1'b1;
                end
                
                DONE: begin
                    ready_in <= 1'b0;
                    valid_out <= 1'b1;
                    P <= A;
                    if (ready_out) begin
                        valid_out <= 1'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule