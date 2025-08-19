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
    reg found; // 添加标志位以避免使用break
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= {INTS_PER_CORE{1'b0}};
                ipi_pending[c] <= {CORES{1'b0}};
                int_to_core[c] <= 1'b0;
                int_id[c] <= 3'd0;
            end
        end else begin
            // 处理常规中断
            for (c = 0; c < CORES; c = c + 1) begin
                // 锁存每个核心的待处理中断
                int_pending[c] <= int_pending[c] | int_src[c*INTS_PER_CORE +: INTS_PER_CORE];
                
                // 处理核间中断
                if (ipi_req[c]) begin
                    ipi_pending[ipi_target[c]][c] <= 1'b1;
                end
                
                // 生成到核心的中断
                if (!int_to_core[c]) begin
                    found = 0;
                    if (|ipi_pending[c]) begin
                        // IPI优先级更高
                        for (t = 0; t < CORES; t = t + 1) begin
                            if (ipi_pending[c][t] && !found) begin
                                int_id[c] <= {1'b1, t[1:0]};  // IPI使用4-7
                                int_to_core[c] <= 1'b1;
                                ipi_pending[c][t] <= 1'b0;
                                found = 1; // 使用标志位而不是break
                            end
                        end
                    end else if (|int_pending[c]) begin
                        int_id[c] <= get_int_id(int_pending[c]);
                        int_to_core[c] <= 1'b1;
                        int_pending[c][int_id[c]] <= 1'b0;
                    end
                end else if (int_ack[c]) begin
                    int_to_core[c] <= 1'b0;
                end
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