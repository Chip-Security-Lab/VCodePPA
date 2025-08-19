//SystemVerilog
// SystemVerilog
module param_crossbar #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire [WIDTH-1:0] in [0:PORTS-1],
    input wire [$clog2(PORTS)-1:0] sel [0:PORTS-1],
    input wire enable,
    output reg [WIDTH-1:0] out [0:PORTS-1]
);
    // Flexible crossbar with configurable ports and widths
    integer i;
    wire [WIDTH-1:0] selected_inputs [0:PORTS-1];
    
    // Selection logic
    genvar g;
    generate
        for (g = 0; g < PORTS; g = g + 1) begin: select_input
            assign selected_inputs[g] = in[sel[g]];
        end
    endgenerate
    
    // Output registers with Brent-Kung adder for accumulation
    always @(posedge clock) begin
        // 使用case语句替代if-else级联结构
        case ({reset, enable})
            2'b10, 2'b11: begin // reset为1
                for (i = 0; i < PORTS; i = i + 1)
                    out[i] <= {WIDTH{1'b0}};
            end
            2'b01: begin // reset为0且enable为1
                for (i = 0; i < PORTS; i = i + 1) begin
                    // Use Brent-Kung addition for each output update
                    out[i] <= brent_kung_add(selected_inputs[i], {WIDTH{1'b0}});
                end
            end
            default: begin // reset为0且enable为0，保持输出不变
                // 保持当前状态
            end
        endcase
    end
    
    // Brent-Kung adder function
    function [WIDTH-1:0] brent_kung_add;
        input [WIDTH-1:0] a, b;
        reg [WIDTH-1:0] sum;
        reg [WIDTH:0] carries;
        reg [WIDTH-1:0] p, g; // Propagate and generate signals
        integer level, offset, j;
        
        begin
            // Step 1: Generate initial P and G values
            for (j = 0; j < WIDTH; j = j + 1) begin
                p[j] = a[j] ^ b[j];  // Propagate
                g[j] = a[j] & b[j];  // Generate
            end
            
            carries[0] = 1'b0; // No carry-in
            
            // Step 2: Compute group P and G - Prefix tree computation
            // 使用case语句重构Brent-Kung加法器的计算流程
            // First prefix level - pairs
            for (j = 0; j < WIDTH; j = j + 2) begin
                case (j+1 < WIDTH)
                    1'b1: carries[j+2] = g[j+1] | (p[j+1] & g[j]); // Combine (j,j+1)
                    default: ; // 不执行操作
                endcase
            end
            
            // Second prefix level - groups of 4
            for (j = 0; j < WIDTH; j = j + 4) begin
                case (j+3 < WIDTH)
                    1'b1: carries[j+4] = carries[j+2] | (p[j+3] & p[j+2] & carries[j]); // Combine groups
                    default: ; // 不执行操作
                endcase
            end
            
            // Fill in missing carries
            for (j = 0; j < WIDTH; j = j + 1) begin
                case (j % 4)
                    1, 2, 3: begin // j % 4 != 0
                        case (j % 2)
                            0: carries[j+1] = g[j] | (p[j] & carries[j-1]);
                            1: carries[j+1] = g[j] | (p[j] & carries[j-2]);
                        endcase
                    end
                    default: ; // 不执行操作
                endcase
            end
            
            // Step 3: Compute sum
            for (j = 0; j < WIDTH; j = j + 1) begin
                sum[j] = p[j] ^ carries[j];
            end
            
            brent_kung_add = sum;
        end
    endfunction

endmodule