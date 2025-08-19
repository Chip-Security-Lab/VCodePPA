//SystemVerilog
module booth_mult (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    output wire ready_o,
    input wire [7:0] X,
    input wire [7:0] Y,
    output wire valid_o,
    input wire ready_i,
    output wire [15:0] P
);

    reg [15:0] A;
    reg [8:0] Q;
    reg [2:0] state;
    reg [2:0] count;
    reg [15:0] result;
    reg result_valid;
    
    localparam IDLE = 3'b000;
    localparam COMPUTE = 3'b001;
    localparam DONE = 3'b010;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 3'b0;
            A <= 16'b0;
            Q <= 9'b0;
            result <= 16'b0;
            result_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_i) begin
                        A <= 16'b0;
                        Q <= {Y, 1'b0};
                        count <= 3'b0;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    if (count < 8) begin
                        case(Q[1:0])
                            2'b01: A <= kogge_stone_adder(A, {X, 8'b0});
                            2'b10: A <= kogge_stone_adder(A, ~{X, 8'b0} + 1'b1);
                            default: ;
                        endcase
                        {A, Q} <= {A[15], A, Q[8:1]};
                        count <= count + 1;
                    end else begin
                        result <= A;
                        result_valid <= 1'b1;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    if (ready_i) begin
                        result_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    assign ready_o = (state == IDLE);
    assign valid_o = result_valid;
    assign P = result;

    function [15:0] kogge_stone_adder;
        input [15:0] a, b;
        reg [15:0] g, p, c;
        integer i, j;
        begin
            for(i=0; i<16; i=i+1) begin
                g[i] = a[i] & b[i];
                p[i] = a[i] ^ b[i];
            end
            
            for(j=0; j<4; j=j+1) begin
                for(i=0; i<16; i=i+1) begin
                    if(i >= (1<<j)) begin
                        g[i] = g[i] | (p[i] & g[i-(1<<j)]);
                        p[i] = p[i] & p[i-(1<<j)];
                    end
                end
            end
            
            c[0] = 1'b0;
            for(i=1; i<16; i=i+1) begin
                c[i] = g[i-1];
            end
            
            kogge_stone_adder = p ^ c;
        end
    endfunction
endmodule