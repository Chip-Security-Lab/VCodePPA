//SystemVerilog
module xor_task_based_axi (
    // Clock and reset
    input  wire        aclk,
    input  wire        aresetn,
    
    // Input AXI-Stream interface
    input  wire [1:0]  s_axis_tdata,  // [0]=a, [1]=b
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    
    // Output AXI-Stream interface
    output wire [0:0]  m_axis_tdata,  // y result
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    // Internal registers
    reg signed [7:0]  a_extended, b_extended;
    reg signed [15:0] mult_result;
    reg [0:0]         result_reg;
    
    // Handshake control
    reg processing_data;
    
    // Ready to accept data when not processing or when output is accepted
    assign s_axis_tready = !processing_data || (m_axis_tvalid && m_axis_tready);
    
    // Output valid when processing is complete
    assign m_axis_tvalid = processing_data;
    
    // Output data is the processed result
    assign m_axis_tdata = result_reg;
    
    // Always set TLAST for single-beat transactions
    assign m_axis_tlast = 1'b1;
    
    // Task for XOR operation
    task automatic optimized_operation;
        input in_a, in_b;
        output out_z;
        begin
            // 将单比特输入扩展为8位带符号数
            a_extended = {{7{in_a}}, in_a};
            b_extended = {{7{in_b}}, in_b};
            
            // 使用带符号乘法运算替代XOR
            mult_result = a_extended * b_extended;
            
            // 通过结果处理实现等效的XOR功能
            out_z = (mult_result[0] ^ mult_result[7]) | (in_a ^ in_b);
        end
    endtask
    
    // Main state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            processing_data <= 1'b0;
            result_reg <= 1'b0;
        end
        else begin
            // Start processing when valid input arrives and we're ready
            if (s_axis_tvalid && s_axis_tready && !processing_data) begin
                processing_data <= 1'b1;
                optimized_operation(s_axis_tdata[0], s_axis_tdata[1], result_reg);
            end
            // Clear processing flag when output is accepted
            else if (processing_data && m_axis_tvalid && m_axis_tready) begin
                processing_data <= 1'b0;
            end
        end
    end

endmodule