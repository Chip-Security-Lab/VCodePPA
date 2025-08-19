//SystemVerilog
module Matrix_NAND_AXI (
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream input interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    
    // AXI-Stream output interface
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);

    // Internal signals
    reg [3:0] row, col;
    reg input_ready;
    
    // Pipeline registers
    reg [7:0] data_pipeline;
    reg valid_pipeline;
    reg last_pipeline;
    reg [7:0] computation_intermediate;
    
    // Input handshaking
    assign s_axis_tready = input_ready;
    
    // First pipeline stage - capture input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row <= 4'b0;
            col <= 4'b0;
            data_pipeline <= 8'b0;
            valid_pipeline <= 1'b0;
            last_pipeline <= 1'b0;
        end
        else if (s_axis_tvalid && s_axis_tready) begin
            row <= s_axis_tdata[7:4];
            col <= s_axis_tdata[3:0];
            data_pipeline <= s_axis_tdata;
            valid_pipeline <= 1'b1;
            last_pipeline <= s_axis_tlast;
        end
        else if (valid_pipeline && !m_axis_tvalid) begin
            valid_pipeline <= 1'b0;
        end
    end
    
    // Intermediate computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            computation_intermediate <= 8'b0;
        end
        else if (valid_pipeline) begin
            // Breaking down the computation into pipeline stages
            computation_intermediate <= {row, col} & 8'hAA;
        end
    end
    
    // Final computation and output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 8'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end
        else if (valid_pipeline) begin
            m_axis_tdata <= ~computation_intermediate;
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= last_pipeline;
        end
        else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end
    end
    
    // Control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_ready <= 1'b1;
        end
        else begin
            // Default state
            input_ready <= 1'b1;
            
            // Block new inputs when pipeline is busy
            if (valid_pipeline && !m_axis_tready) begin
                input_ready <= 1'b0;
            end
            
            // Accept new inputs when output transaction completes
            if (m_axis_tvalid && m_axis_tready) begin
                input_ready <= 1'b1;
            end
        end
    end

endmodule