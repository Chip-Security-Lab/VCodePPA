//SystemVerilog
module QoSArbiter #(parameter QW=4) (
    input clk, rst_n,
    input [4*QW-1:0] qos,
    input [3:0] req,
    output reg [3:0] grant
);

// Buffer registers for high fanout signals
reg [4*QW-1:0] qos_buf;
reg [3:0] req_buf;
wire [QW-1:0] qos_array [0:3];
reg [QW-1:0] qos_array_buf [0:3];
reg [QW-1:0] max_qos_stage1;
reg [QW-1:0] max_qos_stage2;
reg [QW-1:0] max_qos;
reg [3:0] req_pipe;
reg [QW-1:0] qos_array_pipe [0:3];

// Input buffering stage
always @(posedge clk) begin
    if (!rst_n) begin
        qos_buf <= 0;
        req_buf <= 0;
    end else begin
        qos_buf <= qos;
        req_buf <= req;
    end
end

// Extract individual QoS values with buffering
assign qos_array[0] = qos_buf[0*QW +: QW];
assign qos_array[1] = qos_buf[1*QW +: QW];
assign qos_array[2] = qos_buf[2*QW +: QW];
assign qos_array[3] = qos_buf[3*QW +: QW];

// Stage 1: Compare first two pairs with buffering
always @(posedge clk) begin
    if (!rst_n) begin
        max_qos_stage1 <= 0;
        max_qos_stage2 <= 0;
        max_qos <= 0;
        req_pipe <= 0;
        qos_array_pipe[0] <= 0;
        qos_array_pipe[1] <= 0;
        qos_array_pipe[2] <= 0;
        qos_array_pipe[3] <= 0;
        qos_array_buf[0] <= 0;
        qos_array_buf[1] <= 0;
        qos_array_buf[2] <= 0;
        qos_array_buf[3] <= 0;
    end else begin
        // Buffer qos_array values
        qos_array_buf[0] <= qos_array[0];
        qos_array_buf[1] <= qos_array[1];
        qos_array_buf[2] <= qos_array[2];
        qos_array_buf[3] <= qos_array[3];
        
        // First stage comparison with buffered values
        max_qos_stage1 <= (qos_array_buf[0] > qos_array_buf[1]) ? qos_array_buf[0] : qos_array_buf[1];
        max_qos_stage2 <= (qos_array_buf[2] > qos_array_buf[3]) ? qos_array_buf[2] : qos_array_buf[3];
        
        // Pipeline registers
        req_pipe <= req_buf;
        qos_array_pipe[0] <= qos_array_buf[0];
        qos_array_pipe[1] <= qos_array_buf[1];
        qos_array_pipe[2] <= qos_array_buf[2];
        qos_array_pipe[3] <= qos_array_buf[3];
    end
end

// Stage 2: Final comparison with buffering
reg [QW-1:0] max_qos_stage1_buf;
reg [QW-1:0] max_qos_stage2_buf;

always @(posedge clk) begin
    if (!rst_n) begin
        max_qos_stage1_buf <= 0;
        max_qos_stage2_buf <= 0;
        max_qos <= 0;
    end else begin
        max_qos_stage1_buf <= max_qos_stage1;
        max_qos_stage2_buf <= max_qos_stage2;
        max_qos <= (max_qos_stage1_buf > max_qos_stage2_buf) ? max_qos_stage1_buf : max_qos_stage2_buf;
    end
end

// Stage 3: Grant generation with buffering
reg [QW-1:0] max_qos_buf;

always @(posedge clk) begin
    if (!rst_n) begin
        max_qos_buf <= 0;
        grant <= 0;
    end else begin
        max_qos_buf <= max_qos;
        grant <= req_pipe & (
            (qos_array_pipe[0] == max_qos_buf) ? 4'b0001 :
            (qos_array_pipe[1] == max_qos_buf) ? 4'b0010 :
            (qos_array_pipe[2] == max_qos_buf) ? 4'b0100 : 4'b1000);
    end
end

endmodule