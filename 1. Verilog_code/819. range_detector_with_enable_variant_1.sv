//SystemVerilog
module range_detector_axi_stream(
    input wire clk,
    input wire rst_n,
    input wire [15:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [15:0] range_min,
    input wire [15:0] range_max,
    output wire m_axis_tvalid,
    output wire [15:0] m_axis_tdata,
    input wire m_axis_tready
);

    reg range_detect_flag;
    wire comp_out;
    reg [1:0] state;
    reg [15:0] data_reg;
    
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam WAIT_READY = 2'b10;
    
    comparator_module comp1(
        .data(data_reg),
        .lower(range_min),
        .upper(range_max),
        .in_range(comp_out)
    );
    
    assign s_axis_tready = (state == IDLE);
    assign m_axis_tvalid = (state == WAIT_READY);
    assign m_axis_tdata = {15'b0, range_detect_flag};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            range_detect_flag <= 1'b0;
            data_reg <= 16'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        data_reg <= s_axis_tdata;
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    range_detect_flag <= comp_out;
                    state <= WAIT_READY;
                end
                
                WAIT_READY: begin
                    if (m_axis_tready) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

module comparator_module(
    input wire [15:0] data,
    input wire [15:0] lower,
    input wire [15:0] upper,
    output wire in_range
);
    assign in_range = (data >= lower) && (data <= upper);
endmodule