//SystemVerilog
module metastability_rng_axi_stream (
    input  wire        clk_sys,
    input  wire        rst_n,
    input  wire        meta_clk,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    reg meta_stage1, meta_stage2;
    reg [7:0] random_value_reg;
    reg [7:0] random_value_next;
    reg       tvalid_reg, tvalid_next;

    // Metastable input using clock domain crossing
    always @(posedge meta_clk or negedge rst_n) begin
        if (!rst_n)
            meta_stage1 <= 1'b0;
        else
            meta_stage1 <= ~meta_stage1;
    end

    // Capture metastable signal
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            meta_stage2 <= 1'b0;
        else 
            meta_stage2 <= meta_stage1;
    end

    // Random value and TVALID update logic (if-else ladder converted to case)
    always @(*) begin
        random_value_next = random_value_reg;
        tvalid_next = tvalid_reg;
        unique case ({tvalid_reg, m_axis_tready})
            2'b11: begin // tvalid_reg = 1, m_axis_tready = 1
                random_value_next = {random_value_reg[6:0], meta_stage2 ^ random_value_reg[7]};
                tvalid_next = 1'b1;
            end
            2'b01: begin // tvalid_reg = 0, m_axis_tready = 1
                random_value_next = {random_value_reg[6:0], meta_stage2 ^ random_value_reg[7]};
                tvalid_next = 1'b1;
            end
            2'b10: begin // tvalid_reg = 1, m_axis_tready = 0
                // Hold values
            end
            2'b00: begin // tvalid_reg = 0, m_axis_tready = 0
                random_value_next = {random_value_reg[6:0], meta_stage2 ^ random_value_reg[7]};
                tvalid_next = 1'b1;
            end
        endcase
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_value_reg <= 8'h42;
            tvalid_reg <= 1'b0;
        end else begin
            random_value_reg <= random_value_next;
            tvalid_reg <= tvalid_next;
        end
    end

    assign m_axis_tdata  = random_value_reg;
    assign m_axis_tvalid = tvalid_reg;

endmodule