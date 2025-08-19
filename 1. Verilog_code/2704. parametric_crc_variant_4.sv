//SystemVerilog
module parametric_crc #(
    parameter WIDTH = 8,
    parameter POLY = 8'h9B,
    parameter INIT = {WIDTH{1'b1}},
    parameter PIPE_STAGES = 4
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [WIDTH-1:0] data_in,
    output wire valid_out,
    output wire [WIDTH-1:0] crc_out,
    output wire ready
);

    localparam CHUNK_SIZE = (WIDTH + PIPE_STAGES - 1) / PIPE_STAGES;
    
    // 流水线寄存器
    reg [WIDTH-1:0] data_stage[PIPE_STAGES-1:0];
    reg [WIDTH-1:0] crc_stage[PIPE_STAGES:0];
    reg [PIPE_STAGES:0] valid_stage;
    reg processing;
    
    // 组合逻辑输出
    wire [WIDTH-1:0] next_crc[PIPE_STAGES:0];
    wire [PIPE_STAGES-1:0] process_chunk;
    wire [WIDTH-1:0] chunk_crc[PIPE_STAGES-1:0];
    
    // 组合逻辑
    assign ready = !processing || !valid_stage[PIPE_STAGES-1];
    assign valid_out = valid_stage[PIPE_STAGES];
    assign crc_out = crc_stage[PIPE_STAGES];
    
    genvar i;
    generate
        for (i = 0; i < PIPE_STAGES; i = i + 1) begin : gen_pipeline
            assign process_chunk[i] = valid_stage[i] && (!valid_stage[i+1] || ready);
            assign chunk_crc[i] = compute_chunk_crc(data_stage[i], crc_stage[i], i);
        end
    endgenerate
    
    // 时序逻辑 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage[0] <= 1'b0;
            crc_stage[0] <= INIT;
            processing <= 1'b0;
        end else begin
            if (valid_in && ready) begin
                data_stage[0] <= data_in;
                valid_stage[0] <= 1'b1;
                processing <= 1'b1;
                if (!processing) begin
                    crc_stage[0] <= INIT;
                end
            end else if (process_chunk[0] && !valid_in) begin
                valid_stage[0] <= 1'b0;
                if (!valid_stage[1]) begin
                    processing <= 1'b0;
                end
            end
        end
    end
    
    // 时序逻辑 - 后续流水线级
    generate
        for (i = 0; i < PIPE_STAGES; i = i + 1) begin : gen_pipe_stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    valid_stage[i+1] <= 1'b0;
                    crc_stage[i+1] <= INIT;
                end else begin
                    if (process_chunk[i]) begin
                        crc_stage[i+1] <= chunk_crc[i];
                        valid_stage[i+1] <= valid_stage[i];
                        if (i < PIPE_STAGES-1) begin
                            data_stage[i+1] <= data_stage[i];
                        end
                    end else if (valid_stage[i+1] && ready && !valid_stage[i]) begin
                        valid_stage[i+1] <= 1'b0;
                    end
                end
            end
        end
    endgenerate
    
    // CRC计算函数
    function [WIDTH-1:0] compute_chunk_crc;
        input [WIDTH-1:0] data;
        input [WIDTH-1:0] crc_in;
        input integer stage;
        
        integer j, start_bit, end_bit;
        reg [WIDTH-1:0] temp_crc;
        begin
            temp_crc = crc_in;
            start_bit = stage * CHUNK_SIZE;
            end_bit = ((stage + 1) * CHUNK_SIZE > WIDTH) ? WIDTH - 1 : (stage + 1) * CHUNK_SIZE - 1;
            
            for (j = start_bit; j <= end_bit; j = j + 1) begin
                temp_crc = (temp_crc << 1) ^ ((data[j] ^ temp_crc[WIDTH-1]) ? POLY : 0);
            end
            
            compute_chunk_crc = temp_crc;
        end
    endfunction

endmodule