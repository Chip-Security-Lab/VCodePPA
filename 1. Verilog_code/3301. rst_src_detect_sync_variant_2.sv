//SystemVerilog
// SystemVerilog
module rst_src_detect_axi_stream (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        por_n,
    input  wire        wdt_n,
    input  wire        ext_n,
    input  wire        sw_n,
    output wire [3:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    reg [3:0] rst_src_reg;
    reg       tvalid_reg;
    reg       tlast_reg;

    //-------------------------------------------------------------------------------
    // Reset Source Register Update
    //-------------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_src_reg <= 4'b0000;
        end else begin
            rst_src_reg[0] <= ~por_n;
            rst_src_reg[1] <= ~wdt_n;
            rst_src_reg[2] <= ~ext_n;
            rst_src_reg[3] <= ~sw_n;
        end
    end

    //-------------------------------------------------------------------------------
    // AXI Stream tvalid Signal Control
    //-------------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tvalid_reg <= 1'b0;
        end else begin
            if (!tvalid_reg || (tvalid_reg && m_axis_tready)) begin
                tvalid_reg <= 1'b1;
            end
            if (tvalid_reg && m_axis_tready) begin
                tvalid_reg <= 1'b0;
            end
        end
    end

    //-------------------------------------------------------------------------------
    // AXI Stream tlast Signal Control (Constant High After Reset)
    //-------------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlast_reg <= 1'b0;
        end else begin
            tlast_reg <= 1'b1;
        end
    end

    assign m_axis_tdata  = rst_src_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = tlast_reg;

endmodule