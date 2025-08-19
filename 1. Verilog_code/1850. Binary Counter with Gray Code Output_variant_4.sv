//SystemVerilog
module binary_gray_counter #(
    parameter WIDTH = 8,
    parameter MAX_COUNT = {WIDTH{1'b1}}
) (
    input  wire                 clock_in,
    input  wire                 reset_n,
    input  wire                 enable_in,
    input  wire                 up_down_n,  // 1=up, 0=down
    output reg  [WIDTH-1:0]     binary_count,
    output wire [WIDTH-1:0]     gray_count,
    output wire                 terminal_count
);

    // 并行前缀减法器信号声明
    wire [WIDTH-1:0] next_down_count;
    wire [WIDTH-1:0] borrow_propagate;
    wire [WIDTH-1:0] borrow_generate;
    wire [WIDTH-1:0] borrow_carry;
    
    // 生成和传播信号计算
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pp_sub
            assign borrow_generate[i] = ~binary_count[i];
            assign borrow_propagate[i] = binary_count[i];
        end
    endgenerate
    
    // 并行前缀进位计算
    assign borrow_carry[0] = 1'b1;  // 初始借位
    assign borrow_carry[1] = borrow_generate[0] | (borrow_propagate[0] & borrow_carry[0]);
    assign borrow_carry[2] = borrow_generate[1] | (borrow_propagate[1] & borrow_carry[1]);
    assign borrow_carry[3] = borrow_generate[2] | (borrow_propagate[2] & borrow_carry[2]);
    assign borrow_carry[4] = borrow_generate[3] | (borrow_propagate[3] & borrow_carry[3]);
    assign borrow_carry[5] = borrow_generate[4] | (borrow_propagate[4] & borrow_carry[4]);
    assign borrow_carry[6] = borrow_generate[5] | (borrow_propagate[5] & borrow_carry[5]);
    assign borrow_carry[7] = borrow_generate[6] | (borrow_propagate[6] & borrow_carry[6]);
    
    // 减法结果计算
    assign next_down_count = (binary_count == {WIDTH{1'b0}}) ? MAX_COUNT : 
                            binary_count ^ {borrow_carry[WIDTH-2:0], 1'b1};
    
    // Convert binary to Gray code
    assign gray_count = binary_count ^ {1'b0, binary_count[WIDTH-1:1]};
    
    // Terminal count detection
    assign terminal_count = up_down_n ? (binary_count == MAX_COUNT) : 
                                       (binary_count == {WIDTH{1'b0}});
    
    // Binary counter logic with parallel prefix subtractor
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n)
            binary_count <= {WIDTH{1'b0}};
        else if (enable_in) begin
            if (up_down_n) begin
                if (binary_count == MAX_COUNT)
                    binary_count <= {WIDTH{1'b0}};
                else
                    binary_count <= binary_count + 1'b1;
            end else begin
                binary_count <= next_down_count;
            end
        end
    end
endmodule