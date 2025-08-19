//SystemVerilog
module param_mux_array #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8,
    parameter SEL_BITS = $clog2(CHANNELS)
)(
    input [WIDTH-1:0] data_in [0:CHANNELS-1],
    input [SEL_BITS-1:0] channel_sel,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] selected_data;
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] prefix_sub_result;
    
    // 桶形移位器实现的多路复用
    wire [WIDTH-1:0] barrel_mux [0:CHANNELS-1];
    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin: barrel_mux_gen
            assign barrel_mux[i] = (channel_sel == i) ? data_in[i] : {WIDTH{1'b0}};
        end
    endgenerate
    
    // 桶形移位器输出选择
    assign selected_data = barrel_mux[0] | barrel_mux[1] | barrel_mux[2] | barrel_mux[3];
    
    // 相邻通道选择减数
    wire [WIDTH-1:0] next_channel_mux [0:CHANNELS-1];
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin: next_channel_gen
            assign next_channel_mux[i] = (channel_sel == i) ? 
                ((i < CHANNELS-1) ? data_in[i+1] : {WIDTH{1'b0}}) : {WIDTH{1'b0}};
        end
    endgenerate
    
    assign subtrahend = next_channel_mux[0] | next_channel_mux[1] | next_channel_mux[2] | next_channel_mux[3];
    
    // 并行前缀减法器实现
    parallel_prefix_subtractor #(
        .WIDTH(WIDTH)
    ) pps_inst (
        .a(selected_data),
        .b(subtrahend),
        .diff(prefix_sub_result)
    );
    
    assign data_out = prefix_sub_result;
endmodule

module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] p;
    wire [WIDTH-1:0] g;
    
    assign p = a ^ b;
    assign g = ~a & b;
    
    wire [WIDTH-1:0] prefix_g [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] prefix_p [0:$clog2(WIDTH)];
    
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_prefix
            assign prefix_g[0][i] = g[i];
            assign prefix_p[0][i] = p[i];
        end
        
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin: prefix_level
            for (j = 0; j < WIDTH; j = j + 1) begin: prefix_bit
                if (j >= (1 << i)) begin
                    assign prefix_g[i+1][j] = prefix_g[i][j] | (prefix_p[i][j] & prefix_g[i][j-(1<<i)]);
                    assign prefix_p[i+1][j] = prefix_p[i][j] & prefix_p[i][j-(1<<i)];
                end else begin
                    assign prefix_g[i+1][j] = prefix_g[i][j];
                    assign prefix_p[i+1][j] = prefix_p[i][j];
                end
            end
        end
    endgenerate
    
    assign borrow[0] = 1'b0;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: calc_borrow
            assign borrow[i+1] = prefix_g[$clog2(WIDTH)][i];
        end
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: calc_diff
            assign diff[i] = p[i] ^ borrow[i];
        end
    endgenerate
endmodule