//SystemVerilog
module cam_5_axi_stream (
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire [15:0] s_axis_tdata,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [15:0] m_axis_tdata,
    output reg m_axis_tlast,
    output reg m_axis_tuser
);

    // Pipeline stage 1 registers
    reg [15:0] input_data_stage1;
    reg write_en_stage1;
    reg [15:0] stored_data_stage1;
    reg tlast_stage1;
    
    // Pipeline stage 2 registers
    reg [15:0] input_data_stage2;
    reg write_en_stage2;
    reg [15:0] stored_data_stage2;
    reg match_stage2;
    reg tlast_stage2;

    // Stage 1: Input capture and write operation
    always @(posedge aclk) begin
        if (!aresetn) begin
            input_data_stage1 <= 16'b0;
            write_en_stage1 <= 1'b0;
            stored_data_stage1 <= 16'b0;
            tlast_stage1 <= 1'b0;
            s_axis_tready <= 1'b1;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                input_data_stage1 <= s_axis_tdata;
                write_en_stage1 <= 1'b1;
                tlast_stage1 <= s_axis_tlast;
                s_axis_tready <= 1'b0;
            end else if (m_axis_tvalid && m_axis_tready) begin
                s_axis_tready <= 1'b1;
            end
            
            if (write_en_stage1) begin
                stored_data_stage1 <= input_data_stage1;
            end
        end
    end

    // Stage 2: Comparison and output generation
    always @(posedge aclk) begin
        if (!aresetn) begin
            input_data_stage2 <= 16'b0;
            write_en_stage2 <= 1'b0;
            stored_data_stage2 <= 16'b0;
            match_stage2 <= 1'b0;
            tlast_stage2 <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                input_data_stage2 <= input_data_stage1;
                write_en_stage2 <= write_en_stage1;
                stored_data_stage2 <= stored_data_stage1;
                tlast_stage2 <= tlast_stage1;
                match_stage2 <= (!write_en_stage1) && (stored_data_stage1 == input_data_stage1);
            end
        end
    end

    // Output stage
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 16'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata <= stored_data_stage2;
                m_axis_tlast <= tlast_stage2;
                m_axis_tuser <= match_stage2;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule