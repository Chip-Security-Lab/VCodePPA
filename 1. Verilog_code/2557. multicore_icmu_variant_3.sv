//SystemVerilog
module multicore_icmu #(
    parameter CORES = 4,
    parameter INTS_PER_CORE = 8
)(
    input clk, rst_n,
    input [INTS_PER_CORE*CORES-1:0] int_src,
    input [CORES-1:0] ipi_req,
    input [1:0] ipi_target [0:CORES-1],
    output reg [CORES-1:0] int_to_core,
    output reg [2:0] int_id [0:CORES-1],
    input [CORES-1:0] int_ack
);
    reg [INTS_PER_CORE-1:0] int_pending [0:CORES-1];
    reg [CORES-1:0] ipi_pending [0:CORES-1];
    
    integer c, t;
    reg found;
    
    // 跳跃进位加法器相关信号
    wire [INTS_PER_CORE-1:0] carry_propagate [0:CORES-1];
    wire [INTS_PER_CORE-1:0] carry_generate [0:CORES-1];
    wire [INTS_PER_CORE:0] carry [0:CORES-1];
    
    // 生成进位传播和生成信号
    genvar i, j;
    generate
        for (i = 0; i < CORES; i = i + 1) begin : gen_core
            for (j = 0; j < INTS_PER_CORE; j = j + 1) begin : gen_bit
                assign carry_propagate[i][j] = int_pending[i][j] | int_src[i*INTS_PER_CORE + j];
                assign carry_generate[i][j] = int_pending[i][j] & int_src[i*INTS_PER_CORE + j];
            end
        end
    endgenerate
    
    // 计算进位
    generate
        for (i = 0; i < CORES; i = i + 1) begin : gen_carry
            assign carry[i][0] = 1'b0;
            for (j = 0; j < INTS_PER_CORE; j = j + 1) begin : gen_carry_bit
                assign carry[i][j+1] = carry_generate[i][j] | (carry_propagate[i][j] & carry[i][j]);
            end
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= {INTS_PER_CORE{1'b0}};
                ipi_pending[c] <= {CORES{1'b0}};
                int_to_core[c] <= 1'b0;
                int_id[c] <= 3'd0;
            end
        end else begin
            for (c = 0; c < CORES; c = c + 1) begin
                // 使用跳跃进位加法器结果更新int_pending
                int_pending[c] <= int_pending[c] ^ int_src[c*INTS_PER_CORE +: INTS_PER_CORE] ^ carry[c][INTS_PER_CORE-1:0];
                
                if (ipi_req[c]) begin
                    ipi_pending[ipi_target[c]][c] <= 1'b1;
                end
                
                case ({int_to_core[c], |ipi_pending[c], |int_pending[c], int_ack[c]})
                    4'b0001: begin
                        int_to_core[c] <= 1'b0;
                    end
                    4'b0010: begin
                        int_id[c] <= get_int_id(int_pending[c]);
                        int_to_core[c] <= 1'b1;
                        int_pending[c][int_id[c]] <= 1'b0;
                    end
                    4'b0100: begin
                        found = 0;
                        for (t = 0; t < CORES; t = t + 1) begin
                            if (ipi_pending[c][t] && !found) begin
                                int_id[c] <= {1'b1, t[1:0]};
                                int_to_core[c] <= 1'b1;
                                ipi_pending[c][t] <= 1'b0;
                                found = 1;
                            end
                        end
                    end
                    default: begin
                        int_to_core[c] <= int_to_core[c];
                        int_id[c] <= int_id[c];
                    end
                endcase
            end
        end
    end
    
    function [2:0] get_int_id;
        input [INTS_PER_CORE-1:0] pending;
        reg [2:0] result;
        integer i;
        begin
            result = 3'd0;
            for (i = 0; i < INTS_PER_CORE; i = i + 1)
                if (pending[i]) result = i[2:0];
            get_int_id = result;
        end
    endfunction
endmodule