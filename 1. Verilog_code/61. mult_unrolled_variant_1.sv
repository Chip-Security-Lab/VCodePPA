//SystemVerilog
module mult_unrolled_axi (
    input clk,
    input rst_n,
    input tvalid,
    output reg tready,
    input [7:0] tdata,
    output reg [7:0] m_tdata,
    output reg m_tvalid,
    input m_tready
);

    // Internal signals
    reg [3:0] x_reg, y_reg;
    reg [7:0] p0_stage1, p1_stage1, p2_stage1, p3_stage1;
    reg [7:0] sum1_stage2, sum2_stage2;
    reg [7:0] result_reg;
    reg data_valid;

    // Input interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 4'b0;
            y_reg <= 4'b0;
            tready <= 1'b1;
            data_valid <= 1'b0;
        end else begin
            if (tvalid && tready) begin
                x_reg <= tdata[3:0];
                y_reg <= tdata[7:4];
                data_valid <= 1'b1;
                tready <= 1'b0;
            end
            if (m_tvalid && m_tready) begin
                tready <= 1'b1;
                data_valid <= 1'b0;
            end
        end
    end

    // Stage 1: Partial product generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p0_stage1 <= 8'b0;
            p1_stage1 <= 8'b0;
            p2_stage1 <= 8'b0;
            p3_stage1 <= 8'b0;
        end else if (data_valid) begin
            p0_stage1 <= y_reg[0] ? {4'b0, x_reg} : 8'b0;
            p1_stage1 <= y_reg[1] ? {3'b0, x_reg, 1'b0} : 8'b0;
            p2_stage1 <= y_reg[2] ? {2'b0, x_reg, 2'b0} : 8'b0;
            p3_stage1 <= y_reg[3] ? {1'b0, x_reg, 3'b0} : 8'b0;
        end
    end

    // Stage 2: First level addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum1_stage2 <= 8'b0;
            sum2_stage2 <= 8'b0;
        end else if (data_valid) begin
            sum1_stage2 <= p0_stage1 + p1_stage1;
            sum2_stage2 <= p2_stage1 + p3_stage1;
        end
    end

    // Stage 3: Final addition and output interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 8'b0;
            m_tvalid <= 1'b0;
            m_tdata <= 8'b0;
        end else if (data_valid) begin
            result_reg <= sum1_stage2 + sum2_stage2;
            m_tvalid <= 1'b1;
            m_tdata <= result_reg;
        end else if (m_tvalid && m_tready) begin
            m_tvalid <= 1'b0;
        end
    end

endmodule