//SystemVerilog
module power_efficient_shifter(
    input clk,
    input req,                  // 请求信号，替代原来的en
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out,
    output reg ack              // 应答信号，替代原来的ready
);
    // Internal pipeline registers
    reg [7:0] stage0_data;
    reg [7:0] stage1_data;
    reg [7:0] stage2_data;
    
    // Stage enable signals
    reg stage0_en, stage1_en, stage2_en;
    
    // Request state tracking
    reg req_processed;
    reg processing;
    
    // Power gating control logic - pre-compute enable signals
    always @(posedge clk) begin
        if (processing) begin
            stage0_en <= shift[0];
            stage1_en <= shift[1];
            stage2_en <= shift[2];
        end else begin
            stage0_en <= 1'b0;
            stage1_en <= 1'b0;
            stage2_en <= 1'b0;
        end
    end
    
    // Request-Acknowledge handshake control
    always @(posedge clk) begin
        if (!processing && req && !req_processed) begin
            processing <= 1'b1;
            req_processed <= 1'b1;
            ack <= 1'b0;
        end else if (processing) begin
            processing <= 1'b0;
            ack <= 1'b1;
        end else if (req_processed && !req) begin
            req_processed <= 1'b0;
            ack <= 1'b0;
        end
    end
    
    // Stage 0: Handle 1-bit shift
    always @(posedge clk) begin
        if (processing) begin
            if (shift[0])
                stage0_data <= {data_in[6:0], 1'b0};
            else
                stage0_data <= data_in;
        end
    end
    
    // Stage 1: Handle 2-bit shift
    always @(posedge clk) begin
        if (processing) begin
            if (stage1_en)
                stage1_data <= {stage0_data[5:0], 2'b0};
            else
                stage1_data <= stage0_data;
        end
    end
    
    // Stage 2: Handle 4-bit shift
    always @(posedge clk) begin
        if (processing) begin
            if (stage2_en)
                stage2_data <= {stage1_data[3:0], 4'b0};
            else
                stage2_data <= stage1_data;
        end
    end
    
    // Final output assignment with clock gating
    always @(posedge clk) begin
        if (processing)
            data_out <= stage2_data;
    end
endmodule