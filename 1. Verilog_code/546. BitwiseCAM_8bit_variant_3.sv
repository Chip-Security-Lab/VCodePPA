//SystemVerilog
module cam_6 (
    input wire aclk,
    input wire aresetn,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tlast,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tlast
);

    reg [7:0] stored_bits;
    reg match_flag;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam RESPONSE = 2'b10;
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            stored_bits <= 8'b0;
            match_flag <= 1'b0;
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'b0;
            m_axis_tlast <= 1'b0;
            state <= IDLE;
        end else begin
            if (state == IDLE && s_axis_tvalid && s_axis_tready) begin
                stored_bits <= s_axis_tdata;
                s_axis_tready <= 1'b0;
                state <= PROCESS;
            end else if (state == PROCESS) begin
                match_flag <= &(~(stored_bits ^ s_axis_tdata));
                m_axis_tdata <= {7'b0, match_flag};
                m_axis_tlast <= 1'b1;
                m_axis_tvalid <= 1'b1;
                state <= RESPONSE;
            end else if (state == RESPONSE && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                s_axis_tready <= 1'b1;
                state <= IDLE;
            end
        end
    end
endmodule