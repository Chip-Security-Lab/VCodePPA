//SystemVerilog
module cascadable_divider_axi (
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire [3:0] s_axis_tdata,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface  
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [3:0] m_axis_tdata,
    output reg m_axis_tlast,
    
    output reg clk_out,
    output reg cascade_out
);

    reg [3:0] counter;
    wire count_max = (counter == 4'd9);
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam WAIT_READY = 2'b10;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            counter <= 4'd0;
            clk_out <= 1'b0;
            cascade_out <= 1'b0;
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 4'd0;
            m_axis_tlast <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_tready <= 1'b1;
                    if (s_axis_tvalid && s_axis_tready) begin
                        state <= TRANSFER;
                        counter <= s_axis_tdata;
                    end
                end
                
                TRANSFER: begin
                    s_axis_tready <= 1'b0;
                    if (count_max) begin
                        counter <= 4'd0;
                        clk_out <= ~clk_out;
                        cascade_out <= 1'b1;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tdata <= counter;
                        m_axis_tlast <= 1'b1;
                        state <= WAIT_READY;
                    end else begin
                        counter <= counter + 4'd1;
                        cascade_out <= 1'b0;
                    end
                end
                
                WAIT_READY: begin
                    if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule