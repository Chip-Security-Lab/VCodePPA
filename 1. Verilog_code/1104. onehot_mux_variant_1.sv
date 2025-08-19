//SystemVerilog
module onehot_mux_axi_stream #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    // AXI-Stream slave interface (inputs)
    input  wire [3:0]            s_axis_one_hot_sel,
    input  wire [DATA_WIDTH-1:0] s_axis_in0,
    input  wire [DATA_WIDTH-1:0] s_axis_in1,
    input  wire [DATA_WIDTH-1:0] s_axis_in2,
    input  wire [DATA_WIDTH-1:0] s_axis_in3,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    // AXI-Stream master interface (output)
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast
);

    // Pipeline Stage 1: Register inputs and selection
    reg [DATA_WIDTH-1:0] stage1_data0;
    reg [DATA_WIDTH-1:0] stage1_data1;
    reg [DATA_WIDTH-1:0] stage1_data2;
    reg [DATA_WIDTH-1:0] stage1_data3;
    reg [3:0]            stage1_one_hot_sel;
    reg                  stage1_tvalid;

    // Pipeline Stage 2: Multiplex selected input
    reg [DATA_WIDTH-1:0] stage2_muxed_data;
    reg                  stage2_tvalid;

    // Pipeline Stage 3: Output registers
    reg [DATA_WIDTH-1:0] stage3_data_out;
    reg                  stage3_tvalid;
    reg                  stage3_tlast;

    // Ready signal: Ready for new input if pipeline is ready to accept new data
    assign s_axis_tready = !stage1_tvalid || (stage1_tvalid && stage2_tvalid && m_axis_tready);

    // Stage 1: Register inputs and selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data0      <= {DATA_WIDTH{1'b0}};
            stage1_data1      <= {DATA_WIDTH{1'b0}};
            stage1_data2      <= {DATA_WIDTH{1'b0}};
            stage1_data3      <= {DATA_WIDTH{1'b0}};
            stage1_one_hot_sel<= 4'b0000;
            stage1_tvalid     <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                stage1_data0       <= s_axis_in0;
                stage1_data1       <= s_axis_in1;
                stage1_data2       <= s_axis_in2;
                stage1_data3       <= s_axis_in3;
                stage1_one_hot_sel <= s_axis_one_hot_sel;
                stage1_tvalid      <= 1'b1;
            end else if (stage2_tvalid && m_axis_tready) begin
                stage1_tvalid      <= 1'b0;
            end
        end
    end

    // Stage 2: Multiplex input based on selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_muxed_data <= {DATA_WIDTH{1'b0}};
            stage2_tvalid     <= 1'b0;
        end else begin
            if (stage1_tvalid && (!stage2_tvalid || (stage2_tvalid && m_axis_tready))) begin
                case (1'b1)
                    stage1_one_hot_sel[0]: stage2_muxed_data <= stage1_data0;
                    stage1_one_hot_sel[1]: stage2_muxed_data <= stage1_data1;
                    stage1_one_hot_sel[2]: stage2_muxed_data <= stage1_data2;
                    stage1_one_hot_sel[3]: stage2_muxed_data <= stage1_data3;
                    default:               stage2_muxed_data <= {DATA_WIDTH{1'b0}};
                endcase
                stage2_tvalid <= 1'b1;
            end else if (stage2_tvalid && m_axis_tready) begin
                stage2_tvalid <= 1'b0;
            end
        end
    end

    // Stage 3: Output registers (AXI-Stream master interface)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data_out <= {DATA_WIDTH{1'b0}};
            stage3_tvalid   <= 1'b0;
            stage3_tlast    <= 1'b0;
        end else begin
            if (stage2_tvalid && (!stage3_tvalid || (stage3_tvalid && m_axis_tready))) begin
                stage3_data_out <= stage2_muxed_data;
                stage3_tvalid   <= 1'b1;
                stage3_tlast    <= 1'b1;
            end else if (stage3_tvalid && m_axis_tready) begin
                stage3_tvalid   <= 1'b0;
                stage3_tlast    <= 1'b0;
            end
        end
    end

    // Drive AXI-Stream outputs from stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            m_axis_tdata  <= stage3_data_out;
            m_axis_tvalid <= stage3_tvalid;
            m_axis_tlast  <= stage3_tlast;
        end
    end

endmodule